# Root folder containing subfolders with .txt files
$InputDir  = ".\aozora_utf8_Rosanjin"
# Single merged output
$OutFile   = "ja_Rosanjin-ud-test.conllu"

# Optional: if 'ginza' isn't on PATH, use python -m ginza (recommended)
$GinzaCmd  = "python"
$GinzaArgsBase = @("-m", "ginza", "-m", "ja_ginza", "-f", "conllu")

# Ensure UTF-8 output
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$writer = New-Object System.IO.StreamWriter($OutFile, $false, $Utf8NoBom)

try {
    Get-ChildItem -Path $InputDir -Recurse -File -Filter "*.txt" |
        Sort-Object FullName |
        ForEach-Object {

            $filePath = $_.FullName
            $fileName = $_.Name       # includes ".txt"
            $baseName = $_.BaseName   # no extension

            # Run GiNZA -> CoNLL-U to STDOUT (no -o); capture as a single string
            $conllu = & $GinzaCmd @($GinzaArgsBase + @($filePath)) 2>&1 | Out-String

            # If ginza emitted errors, fail fast (helps catch encoding issues etc.)
            if ($LASTEXITCODE -ne 0) {
                throw "GiNZA failed for $fileName. Output:`n$conllu"
            }

            # Split into sentence blocks (CoNLL-U sentences are separated by blank lines)
            $blocks = ($conllu -replace "`r","") -split "(\n\s*\n)+" | Where-Object { $_.Trim() -ne "" }

            # Emit newdoc_id ONCE per file
            $writer.WriteLine("# newdoc_id = $fileName")
            $writer.WriteLine()  # optional blank line for readability

            $sentNum = 0
            foreach ($block in $blocks) {
                $sentNum++

                # Per-sentence metadata
                $writer.WriteLine("# sent_id = $baseName-$('{0:D4}' -f $sentNum)")

                # Write sentence block (usually includes # text = ...)
                $writer.WriteLine($block.TrimEnd())
                $writer.WriteLine()  # blank line between sentences
            }
        }
}
finally {
    $writer.Flush()
    $writer.Close()
}

Write-Host "Wrote merged CoNLL-U to: $OutFile"

