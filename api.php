<?php
/**
 * API Endpoint - Handles AJAX requests for database comparison
 * 
 * Accepts POST JSON with database credentials, performs comparison,
 * and returns structured JSON results.
 */
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/src/DbConnection.php';
require_once __DIR__ . '/src/DatabaseComparator.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'error' => 'Only POST method is allowed.']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    echo json_encode(['success' => false, 'error' => 'Invalid JSON input.']);
    exit;
}

// Validate required fields
$required = ['host1', 'user1', 'name1', 'host2', 'user2', 'name2'];
foreach ($required as $field) {
    if (empty($input[$field])) {
        echo json_encode(['success' => false, 'error' => "Missing required field: {$field}"]);
        exit;
    }
}

try {
    $db1 = new DbConnection(
        $input['host1'],
        $input['user1'],
        $input['pass1'] ?? '',
        $input['name1'],
        (int)($input['port1'] ?? 3306)
    );
    $db2 = new DbConnection(
        $input['host2'],
        $input['user2'],
        $input['pass2'] ?? '',
        $input['name2'],
        (int)($input['port2'] ?? 3306)
    );

    $comparator = new DatabaseComparator($db1, $db2);
    $results    = $comparator->compare();
    $fixSql     = $comparator->generateFixSql($results);

    echo json_encode([
        'success' => true,
        'data'    => [
            'results' => $results,
            'fixSql'  => $fixSql,
            'dbNameA' => $input['name1'],
            'dbNameB' => $input['name2'],
        ],
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'error'   => $e->getMessage(),
    ]);
}
