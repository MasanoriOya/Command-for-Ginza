# README — Merge Aozora `.txt` files into a single GiNZA CoNLL-U dataset (PowerShell)

This script recursively walks a root folder containing subfolders of UTF-8 `.txt` files, runs **GiNZA** on each file to produce **CoNLL-U** output, and **merges everything into one `.conllu` file**. It also adds deterministic document/sentence metadata so the merged corpus is easy to index and debug.

---

## What it does

For every `*.txt` file under `$InputDir` (sorted by full path):

1. Runs GiNZA in CoNLL-U mode:

   * `python -m ginza -m ja_ginza -f conllu <file>`
2. Splits GiNZA output into sentence blocks (blank-line separated).
3. Writes to one output file:

   * `# newdoc_id = <filename.txt>` once per input file
   * `# sent_id = <basename>-0001`, `<basename>-0002`, … per sentence block
   * the sentence block itself (typically including `# text = ...`)
4. Ensures the merged file is written as **UTF-8 (no BOM)**.

Output: a single merged file like `ja_Rosanjin-ud-test.conllu`.

---

## Requirements

* **Windows PowerShell** (or PowerShell 7+)
* **Python** available on PATH
* **GiNZA** and the **ja_ginza** model installed

Typical installation (example):

```bash
pip install ginza ja_ginza
```

If you use virtual environments, activate the venv before running the script so `python -m ginza` resolves correctly.

---

## Input / Output layout

### Input

`$InputDir` should point to a directory tree like:

```
aozora_utf8_Rosanjin/
  book1/
    a.txt
    b.txt
  book2/
    c.txt
```

All `.txt` files should be readable as UTF-8 (or at least compatible with how GiNZA reads them).

### Output

A single `.conllu` file:

```
# newdoc_id = a.txt

# sent_id = a-0001
# text = ...
1   ... 

# sent_id = a-0002
# text = ...
1   ...
```

---

## How to run

1. Save the script to a file, e.g. `merge-ginza-conllu.ps1`.
2. Update these variables at the top if needed:

* `$InputDir` — root folder containing `.txt` files
* `$OutFile` — merged output filename

3. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\merge-ginza-conllu.ps1
```

On success you’ll see:

```
Wrote merged CoNLL-U to: ja_Rosanjin-ud-test.conllu
```

---

## Configuration notes

### GiNZA invocation

The script is set up to use:

* `$GinzaCmd  = "python"`
* `$GinzaArgsBase = @("-m", "ginza", "-m", "ja_ginza", "-f", "conllu")`

This is intentional: `python -m ginza ...` is generally more reliable than calling `ginza` directly (PATH issues, multiple Pythons, venvs).

If you *do* want to call `ginza` directly, you can change:

```powershell
$GinzaCmd = "ginza"
$GinzaArgsBase = @("-m", "ja_ginza", "-f", "conllu")
```

(Only do this if `ginza` is definitely on PATH.)

### UTF-8 output without BOM

The output file is written with:

* `System.Text.UTF8Encoding($false)` → UTF-8 **without** BOM

This is often preferred for NLP pipelines and UD tooling.

---

## Error handling

* The script captures **stdout+stderr** from GiNZA (`2>&1 | Out-String`).
* If GiNZA exits non-zero (`$LASTEXITCODE -ne 0`), the script throws an error **immediately** with the captured output. This helps catch:

  * encoding problems
  * missing model / install issues
  * malformed input

---

## Sentence and document IDs

* `newdoc_id` is the literal filename including `.txt`
  Example: `# newdoc_id = myfile.txt`

* `sent_id` is based on the file basename + a 4-digit counter
  Example: `# sent_id = myfile-0007`

This makes sentence IDs stable across reruns as long as:

* file ordering doesn’t change, and
* GiNZA’s sentence splitting remains consistent.

---

## Performance tips (optional)

* Large corpora can take time. If you need speed:

  * run on an SSD
  * ensure you’re using a fast Python environment
  * consider parallelization (not included in this script because it complicates deterministic ordering and merging)

