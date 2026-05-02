import subprocess 
import re

tests = {
    "banking_test.js": [3, 3, 3, 3, 4, 3, 4, 4, 3],
    "exceptions_test.js": [2, 2, 3, 3, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2],
    "interest_test.js": [2, 3, 3, 2, 3, 2, 2, 3],
    "owner_test.js": [1.5] * 10,
}

## print sum of each array
print(sum(tests["banking_test.js"]), 
      sum(tests["exceptions_test.js"]), 
      sum(tests["interest_test.js"]), 
      sum(tests["owner_test.js"]))

results = {}

for file, weights in tests.items():
    print(f"running {file}")
    
    process = subprocess.run(
    f"npx hardhat test test/{file}",
    shell=True,
    text=True,
    capture_output=True,
    encoding="utf-8")
    
    out = process.stdout + process.stderr    

    passed = set()
    failed = set()

    # Parse mocha output
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("√") or line.startswith("✔"):  # Passed
            m = re.search(r"(\d+)\.?_?Test", line)
            if m:
                passed.add(int(m.group(1)))
        elif re.match(r"^\d+\)", line):  # Failed
            m = re.search(r"(\d+)\.?_?Test", line)
            if m:
                failed.add(int(m.group(1)))

    # Build marks vector (same length as weights)
    marks = []
    for idx, weight in enumerate(weights, start=1):
        if idx in passed:
            marks.append(weight)
        else:
            marks.append(0)

    results[file] = marks

for file, marks in results.items():
    print("\n\n", file, sep="")
    for i, mark in enumerate(marks):
        print(f"Test {i}: {"Pass" if marks else "Fail"} - {mark} marks")
    print(f"Total: {sum(marks)} marks\n")    

print("\n\n Grand Total: ", sum(sum(marks) for marks in results.values()), "marks")