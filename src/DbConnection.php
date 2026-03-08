<?php
/**
 * DbConnection - Database connection wrapper
 * 
 * Handles PDO connection and provides methods to query
 * MySQL schema information (tables, columns, indexes, foreign keys).
 */
class DbConnection
{
    public PDO    $pdo;
    public string $dbName;

    public function __construct(
        string $host,
        string $user,
        string $pass,
        string $dbName,
        int    $port = 3306
    ) {
        $this->dbName = $dbName;
        $dsn = "mysql:host={$host};port={$port};dbname={$dbName};charset=utf8mb4";
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_PERSISTENT         => false,
        ];
        $this->pdo = new PDO($dsn, $user, $pass, $options);
    }

    /**
     * Get all table names in the database.
     */
    public function tableNames(): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = ?'
        );
        $stmt->execute([$this->dbName]);
        return array_column($stmt->fetchAll(), 'TABLE_NAME');
    }

    /**
     * Get the CREATE TABLE statement for a table.
     */
    public function showCreateTable(string $table): string
    {
        $stmt = $this->pdo->query("SHOW CREATE TABLE `{$table}`");
        $row  = $stmt->fetch(PDO::FETCH_NUM);
        return $row[1] ?? '';
    }

    /**
     * Get column metadata for a table, indexed by column name.
     */
    public function columns(string $table): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA, ORDINAL_POSITION
             FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
             ORDER BY ORDINAL_POSITION'
        );
        $stmt->execute([$this->dbName, $table]);
        $rows = $stmt->fetchAll();
        $out = [];
        foreach ($rows as $r) {
            $out[$r['COLUMN_NAME']] = $r;
        }
        return $out;
    }

    /**
     * Get index information for a table.
     */
    public function indexes(string $table): array
    {
        $stmt = $this->pdo->query("SHOW INDEX FROM `{$table}`");
        $rows = $stmt->fetchAll();
        // Group by index name
        $grouped = [];
        foreach ($rows as $r) {
            $name = $r['Key_name'];
            if (!isset($grouped[$name])) {
                $grouped[$name] = [
                    'name'      => $name,
                    'unique'    => !$r['Non_unique'],
                    'columns'   => [],
                ];
            }
            $grouped[$name]['columns'][] = $r['Column_name'];
        }
        return $grouped;
    }

    /**
     * Get foreign key constraints for a table.
     */
    public function foreignKeys(string $table): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT CONSTRAINT_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
             FROM information_schema.KEY_COLUMN_USAGE
             WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND REFERENCED_TABLE_NAME IS NOT NULL'
        );
        $stmt->execute([$this->dbName, $table]);
        return $stmt->fetchAll();
    }
}
