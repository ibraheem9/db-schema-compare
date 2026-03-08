<?php
/**
 * DatabaseComparator - Compares two MySQL database schemas
 * 
 * Detects differences in tables, columns, indexes, and foreign keys
 * between two databases and generates SQL fix scripts.
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
     */
    public function generateFixSql(array $diff): array
    {
        $sql = ['a' => [], 'b' => []];

        // 1. Missing tables
        foreach ($diff['missingInB'] as $table => $createSql) {
            $sql['b'][] = $createSql . ';';
        }
        foreach ($diff['missingInA'] as $table => $createSql) {
            $sql['a'][] = $createSql . ';';
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

        return $sql;
    }

    // ---- Private helpers ----

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
