<?php

return [
    'paths' => ['api/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => array_filter(array_map(
        'trim',
        explode(',', env(
            'ADMIN_FRONTEND_URL',
            'https://citygoremit.shop,https://www.citygoremit.shop,http://localhost:5174,http://127.0.0.1:5174'
        ))
    )),

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,
];
