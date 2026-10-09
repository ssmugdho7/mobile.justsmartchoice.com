<?php
// The mobile host distributes the app. CRM authentication and data stay on
// crm.justsmartchoice.com; this directory contains no duplicate CRM backend.
header('Content-Type: text/html; charset=UTF-8');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: strict-origin-when-cross-origin');
readfile(__DIR__ . '/index.html');
