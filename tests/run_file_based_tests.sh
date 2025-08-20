#!/bin/bash
# File-based test runner with dynamic grouping

echo "Celua File-Based Test Suite"
echo "==========================="
echo ""

total_tests=0
total_passed=0

declare -A group_totals
declare -A group_passed

current_group=""

# Find all test.tl files, organize by directory structure
while IFS= read -r -d '' test_file; do
    # Extract group name from path (e.g., "./preprocessing/basic_splicing/test.tl" -> "preprocessing")
    group=$(echo "$test_file" | cut -d'/' -f2)
    subgroup=$(echo "$test_file" | cut -d'/' -f3)
    
    # Initialize group counters if new group
    if [[ "$current_group" != "$group" ]]; then
        if [[ -n "$current_group" ]]; then
            echo ""  # Add space between groups
        fi
        echo "Running group: $group"
        current_group="$group"
        group_totals["$group"]=0
        group_passed["$group"]=0
    fi
    
    echo "  Testing: $subgroup"
    
    total_tests=$((total_tests + 1))
    group_totals["$group"]=$((group_totals["$group"] + 1))
    
    # Run the test and capture output
    if output=$(lua "$test_file" 2>&1); then
        total_passed=$((total_passed + 1))
        group_passed["$group"]=$((group_passed["$group"] + 1))
        echo "    $output"
    else
        echo "    $output"
    fi
    
    echo ""
done < <(find . -name "test.tl" -not -path "./test_utils.tl" -print0 | sort -z)

echo "=" $(printf '%*s' 50 '' | tr ' ' '=')
echo "TEST SUMMARY"
echo "=" $(printf '%*s' 50 '' | tr ' ' '=')

# Print group statistics
for group in $(printf '%s\n' "${!group_totals[@]}" | sort); do
    passed=${group_passed["$group"]}
    total=${group_totals["$group"]}
    if [[ $total -gt 0 ]]; then
        percentage=$(( (passed * 100) / total ))
        if [[ $percentage -eq 100 ]]; then
            icon="✓"
        else
            icon="✗"
        fi
        printf "%s %s: %d/%d (%.1f%%)\n" "$icon" "$group" "$passed" "$total" "$percentage"
    fi
done

echo ""
if [[ $total_tests -gt 0 ]]; then
    overall_percentage=$(( (total_passed * 100) / total_tests ))
    printf "OVERALL: %d/%d tests passed (%.1f%%)\n" "$total_passed" "$total_tests" "$overall_percentage"
else
    echo "OVERALL: 0/0 tests passed (100.0%)"
fi

if [[ "$total_passed" -eq "$total_tests" ]]; then
    echo "🎉 All tests passed!"
    exit 0
else
    exit 1
fi