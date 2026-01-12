#!/bin/bash

echo "========================================================"
echo "   KWALEGEND DIAGNOSTIC TOOL - v1.2"
echo "   Scanning Project Health..."
echo "========================================================"
echo ""

# 1. FILE EXISTENCE CHECK (Did files move?)
echo "1. Checking Critical File Paths..."
FILES=(
    "lib/main.dart"
    "lib/app_init.dart"
    "lib/services/database_serv.dart"
    "lib/services/auth/auth_serv.dart"
    "lib/repo/dashboard_repo.dart"
    "lib/vmodels/finance_vmodel.dart"
    "lib/vmodels/students_vmodel.dart"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ Found: $file"
    else
        echo "   ❌ MISSING: $file"
        echo "      -> Check if you moved this file or changed the folder name."
    fi
done
echo ""

# 2. CHECK MAIN.DART PROVIDERS
echo "2. Checking main.dart Injection..."
if grep -q "Provider<FinanceRepository>" lib/main.dart && grep -q "Provider<StudentRepository>" lib/main.dart; then
    echo "   ✅ Repositories injected correctly."
else
    echo "   ❌ CRITICAL: Finance/Student Repos missing in main.dart providers."
fi
echo ""

# 3. CHECK DATABASE SERVICE
echo "3. Checking Database Service..."
if grep -q "initializeStandalone" lib/services/database_serv.dart; then
    echo "   ✅ Standalone Init found."
else
    echo "   ⚠️ WARNING: initializeStandalone missing. AppInit might crash."
fi
echo ""

# 4. RUN FLUTTER ANALYZE
echo "4. Running Flutter Analyze (The Truth Teller)..."
echo "   (This finds every broken import and syntax error)"
echo "   ------------------------------------------------"
flutter analyze > analysis_report.txt 2>&1

# Count errors
ERROR_COUNT=$(grep -c "error •" analysis_report.txt)
if [ $ERROR_COUNT -eq 0 ]; then
    echo "   ✅ ZERO ERRORS. The project structure is valid."
else
    echo "   🔥 FOUND $ERROR_COUNT ERRORS."
    echo "   -> OPEN 'analysis_report.txt' NOW."
    echo "   -> Look for 'Target of URI doesn't exist' (Broken Import)."
    echo "   -> Look for 'Undefined name' (Missing Provider)."
fi

echo ""
echo "========================================================"
