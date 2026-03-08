<?php
/**
 * DB Compare - MySQL Schema Comparator (Single-File Fallback)
 * 
 * This file serves as the traditional PHP entry point.
 * It loads the same index.html interface.
 * The API endpoint (api.php) handles the actual comparison logic.
 */

// If accessed directly, serve the HTML interface
$htmlFile = __DIR__ . '/index.html';
if (file_exists($htmlFile)) {
    readfile($htmlFile);
    exit;
}

// Fallback: redirect to index.html
header('Location: index.html');
exit;
