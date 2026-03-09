<?php
/**
 * DatabaseComparator - Compares two MySQL database schemas
 * 
 * Detects differences in tables, columns, indexes, and foreign keys
 * between two databases and generates SQL fix scripts.
 * 
 * CREATE TABLE statements are automatically sorted by foreign key
 * dependency order to prevent reference errors during execution.
 */
class DatabaseComparator
{
    private DbConnection $a;
    private DbConnection $b;

    public function __construct(DbConnection $a, DbConnection $b)
    {
        $this->a = $a; // source (Database A)
        $this->b = $b; // target (Database B)
    }

    /**
     * Compare the two databases and return a structured diff array.
     *
     * Returns:
     *   missingInB   => [table => createSql]
     *   missingInA   => [table => createSql]
     *   columnDiffs  => [table => [missingInB, missingInA, differing]]
     *   indexDiffs   => [table => [missingInB, missingInA, differing]]
     *   fkDiffs      => [table => [missingInB, missingInA]]
     *   stats        => [tablesA, tablesB, commonTables, totalDiffs]
     */
    public function compare(): array
    {
        $diff = [
            'missingInB'  => [],
            'missingInA'  => [],
            'columnDiffs' => [],
            'indexDiffs'  => [],
            'fkDiffs'     => [],
            'stats'       => [],
        ];

        // --- TABLES ---
        $tablesA = $this->a->tableNames();
        $tablesB = $this->b->tableNames();

        $missingInB = array_diff($tablesA, $tablesB);
        $missingInA = array_diff($tablesB, $tablesA);

        foreach ($missingInB as $t) {
            $diff['missingInB'][$t] = $this->a->showCreateTable($t);
        }
        foreach ($missingInA as $t) {
            $diff['missingInA'][$t] = $this->b->showCreateTable($t);
        }

        // --- COMMON TABLES: COLUMNS, INDEXES, FOREIGN KEYS ---
        $commonTables = array_intersect($tablesA, $tablesB);
        foreach ($commonTables as $table) {
            $this->compareColumns($table, $diff);
            $this->compareIndexes($table, $diff);
            $this->compareForeignKeys($table, $diff);
        }

        // --- STATS ---
        $totalDiffs = count($diff['missingInB']) + count($diff['missingInA'])
                    + count($diff['columnDiffs']) + count($diff['indexDiffs'])
                    + count($diff['fkDiffs']);

        $diff['stats'] = [
            'tablesA'      => count($tablesA),
            'tablesB'      => count($tablesB),
            'commonTables' => count($commonTables),
            'totalDiffs'   => $totalDiffs,
        ];

        return $diff;
    }

    /**
     * Generate SQL fix statements from a diff array.
     * 
     * CREATE TABLE statements are sorted by foreign key dependency order
     * so that referenced tables are created before tables that reference them.
     * The execution order is:
     *   1. CREATE TABLE (dependency-sorted)
     *   2. ALTER TABLE ... ADD COLUMN / MODIFY COLUMN
     *   3. ALTER TABLE ... ADD INDEX
     *   4. ALTER TABLE ... ADD CONSTRAINT (foreign keys)
     */
    public function generateFixSql(array $diff): array
    {
        $sql = ['a' => [], 'b' => []];

        // 1. Missing tables — sorted by FK dependency order
        $createForB = [];
        foreach ($diff['missingInB'] as $table => $createSql) {
            $createForB[$table] = $createSql . ';';
        }
        $createForA = [];
        foreach ($diff['missingInA'] as $table => $createSql) {
            $createForA[$table] = $createSql . ';';
        }

        // Sort CREATE TABLE statements by dependency order
        $sortedForB = $this->sortByDependency($createForB);
        $sortedForA = $this->sortByDependency($createForA);

        foreach ($sortedForB as $stmt) {
            $sql['b'][] = $stmt;
        }
        foreach ($sortedForA as $stmt) {
            $sql['a'][] = $stmt;
        }

        // 2. Column issues
        foreach ($diff['columnDiffs'] as $table => $d) {
            foreach ($d['missingInB'] as $col => $meta) {
                $sql['b'][] = $this->addColumnSql($table, $meta);
            }
            foreach ($d['missingInA'] as $col => $meta) {
                $sql['a'][] = $this->addColumnSql($table, $meta);
            }
            foreach ($d['differing'] as $colName => $pair) {
                $sql['b'][] = $this->modifyColumnSql($table, $pair['a']);
                $sql['a'][] = $this->modifyColumnSql($table, $pair['b']);
            }
        }

        // 3. Index issues
        foreach ($diff['indexDiffs'] as $table => $d) {
            foreach ($d['missingInB'] as $name => $idx) {
                $sql['b'][] = $this->addIndexSql($table, $idx);
            }
            foreach ($d['missingInA'] as $name => $idx) {
                $sql['a'][] = $this->addIndexSql($table, $idx);
            }
        }

        // 4. Foreign key issues
        foreach ($diff['fkDiffs'] as $table => $d) {
            foreach ($d['missingInB'] as $name => $fk) {
                $sql['b'][] = $this->addForeignKeySql($table, $fk);
            }
            foreach ($d['missingInA'] as $name => $fk) {
                $sql['a'][] = $this->addForeignKeySql($table, $fk);
            }
        }

        return $sql;
    }

    // ---- Private helpers ----

    /**
     * Sort CREATE TABLE statements by foreign key dependency order.
     * 
     * Parses REFERENCES clauses from each CREATE TABLE statement to build
     * a dependency graph, then performs a topological sort so that tables
     * with no dependencies come first, and tables that reference others
     * come after their dependencies.
     *
     * @param array $createStatements [tableName => createSql]
     * @return array Ordered list of CREATE SQL strings
     */
    private function sortByDependency(array $createStatements): array
    {
        if (count($createStatements) <= 1) {
            return array_values($createStatements);
        }

        $tableNames = array_keys($createStatements);

        // Build dependency graph: table => [list of tables it depends on]
        $dependencies = [];
        foreach ($createStatements as $table => $sql) {
            $dependencies[$table] = [];
            // Match REFERENCES `table_name` patterns in the CREATE TABLE SQL
            if (preg_match_all('/REFERENCES\s+`([^`]+)`/i', $sql, $matches)) {
                foreach ($matches[1] as $refTable) {
                    // Only track dependencies on tables within this same set
                    // (external references to already-existing tables are fine)
                    if (in_array($refTable, $tableNames, true) && $refTable !== $table) {
                        $dependencies[$table][] = $refTable;
                    }
                }
                $dependencies[$table] = array_unique($dependencies[$table]);
            }
        }

        // Topological sort (Kahn's algorithm)
        $sorted = [];
        $remaining = $dependencies;

        // Safety counter to prevent infinite loops on circular references
        $maxIterations = count($remaining) * count($remaining) + 1;
        $iteration = 0;

        while (!empty($remaining) && $iteration < $maxIterations) {
            $iteration++;
            $resolved = false;

            foreach ($remaining as $table => $deps) {
                // Check if all dependencies have been resolved (already in sorted list)
                $unresolved = array_filter($deps, function ($dep) use ($sorted) {
                    return !in_array($dep, $sorted, true);
                });

                if (empty($unresolved)) {
                    $sorted[] = $table;
                    unset($remaining[$table]);
                    $resolved = true;
                }
            }

            // If no progress was made, we have a circular dependency
            // Add remaining tables as-is to avoid infinite loop
            if (!$resolved) {
                foreach ($remaining as $table => $deps) {
                    $sorted[] = $table;
                }
                break;
            }
        }

        // Build the ordered SQL array
        $result = [];
        foreach ($sorted as $table) {
            $result[] = $createStatements[$table];
        }

        return $result;
    }

    private function compareColumns(string $table, array &$diff): void
    {
        $colsA = $this->a->columns($table);
        $colsB = $this->b->columns($table);

        $missingColsInB = array_diff_key($colsA, $colsB);
        $missingColsInA = array_diff_key($colsB, $colsA);

        $differing = [];
        foreach ($colsA as $cName => $metaA) {
            if (!isset($colsB[$cName])) continue;
            $metaB = $colsB[$cName];
            if ($this->colMetaToString($metaA) !== $this->colMetaToString($metaB)) {
                $differing[$cName] = ['a' => $metaA, 'b' => $metaB];
            }
        }

        if ($missingColsInB || $missingColsInA || $differing) {
            $diff['columnDiffs'][$table] = [
                'missingInB' => $missingColsInB,
                'missingInA' => $missingColsInA,
                'differing'  => $differing,
            ];
        }
    }

    private function compareIndexes(string $table, array &$diff): void
    {
        $idxA = $this->a->indexes($table);
        $idxB = $this->b->indexes($table);

        $missingInB = array_diff_key($idxA, $idxB);
        $missingInA = array_diff_key($idxB, $idxA);

        $differing = [];
        foreach ($idxA as $name => $ia) {
            if (!isset($idxB[$name])) continue;
            $ib = $idxB[$name];
            if ($ia['columns'] !== $ib['columns'] || $ia['unique'] !== $ib['unique']) {
                $differing[$name] = ['a' => $ia, 'b' => $ib];
            }
        }

        if ($missingInB || $missingInA || $differing) {
            $diff['indexDiffs'][$table] = [
                'missingInB' => $missingInB,
                'missingInA' => $missingInA,
                'differing'  => $differing,
            ];
        }
    }

    private function compareForeignKeys(string $table, array &$diff): void
    {
        $fkA = $this->a->foreignKeys($table);
        $fkB = $this->b->foreignKeys($table);

        $fkAByName = [];
        foreach ($fkA as $fk) $fkAByName[$fk['CONSTRAINT_NAME']] = $fk;
        $fkBByName = [];
        foreach ($fkB as $fk) $fkBByName[$fk['CONSTRAINT_NAME']] = $fk;

        $missingInB = array_diff_key($fkAByName, $fkBByName);
        $missingInA = array_diff_key($fkBByName, $fkAByName);

        if ($missingInB || $missingInA) {
            $diff['fkDiffs'][$table] = [
                'missingInB' => $missingInB,
                'missingInA' => $missingInA,
            ];
        }
    }

    private function addColumnSql(string $table, array $meta): string
    {
        return sprintf(
            'ALTER TABLE `%s` ADD COLUMN `%s` %s %s %s %s;',
            $table,
            $meta['COLUMN_NAME'],
            $meta['COLUMN_TYPE'],
            $meta['IS_NULLABLE'] === 'NO' ? 'NOT NULL' : 'NULL',
            $meta['COLUMN_DEFAULT'] !== null ? 'DEFAULT ' . $this->quoteDefault($meta['COLUMN_DEFAULT']) : '',
            $meta['EXTRA']
        );
    }

    private function modifyColumnSql(string $table, array $meta): string
    {
        return sprintf(
            'ALTER TABLE `%s` MODIFY COLUMN `%s` %s %s %s %s;',
            $table,
            $meta['COLUMN_NAME'],
            $meta['COLUMN_TYPE'],
            $meta['IS_NULLABLE'] === 'NO' ? 'NOT NULL' : 'NULL',
            $meta['COLUMN_DEFAULT'] !== null ? 'DEFAULT ' . $this->quoteDefault($meta['COLUMN_DEFAULT']) : '',
            $meta['EXTRA']
        );
    }

    private function addIndexSql(string $table, array $idx): string
    {
        $cols = implode('`, `', $idx['columns']);
        $type = $idx['unique'] ? 'UNIQUE INDEX' : 'INDEX';
        return sprintf(
            'ALTER TABLE `%s` ADD %s `%s` (`%s`);',
            $table, $type, $idx['name'], $cols
        );
    }

    private function addForeignKeySql(string $table, array $fk): string
    {
        return sprintf(
            'ALTER TABLE `%s` ADD CONSTRAINT `%s` FOREIGN KEY (`%s`) REFERENCES `%s` (`%s`);',
            $table,
            $fk['CONSTRAINT_NAME'],
            $fk['COLUMN_NAME'],
            $fk['REFERENCED_TABLE_NAME'],
            $fk['REFERENCED_COLUMN_NAME']
        );
    }

    private function quoteDefault(string $value): string
    {
        return is_numeric($value) ? $value : "'" . addslashes($value) . "'";
    }

    private function colMetaToString(array $meta): string
    {
        return implode('|', [
            $meta['COLUMN_TYPE'],
            $meta['IS_NULLABLE'],
            $meta['COLUMN_DEFAULT'] === null ? 'NULL' : $meta['COLUMN_DEFAULT'],
            $meta['EXTRA'],
        ]);
    }
}
