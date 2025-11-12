import json

data = '''
[
    42,
    "example",
    true,
    null,
    { "id": 1, "name": "Alice", "roles": ["admin", "editor"], "active": true },
    [1, 2, 3, { "nestedKey": "nestedValue" }],
    { "timestamp": "2025-08-11T10:15:30Z", "metrics": { "views": 1200, "likes": 300, "conversion": 0.125 } },
    ["mixed", 99, false, { "deep": [1, { "deeper": "yes" }] }],
    { "tags": ["n8n", "api", "json"], "config": { "retry": 3, "timeout": 5000 } }
]
'''

try:
    parsed_data = json.loads(data)
    print("Valid JSON")
except json.JSONDecodeError as e:
    print("Invalid JSON:", e)