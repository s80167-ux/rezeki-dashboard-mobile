#!/bin/bash
echo "Running Rezeki Dashboard with local backend..."
flutter run --dart-define=REZEKI_API_BASE_URL=http://192.168.1.139:4000/api
