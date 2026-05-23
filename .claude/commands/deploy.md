Deploy the site to the FTP server. Run the following command and report the result:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\MindAttic\mindattic.com\deploy.ps1"
```

After running, summarize how many files were uploaded successfully and flag any failures.

Note: do NOT invoke via `cmd /c "D:/.../deploy.bat"` -- the forward slashes in the path get parsed as cmd switches (cmd uses `/` as its switch prefix), so the command silently opens a fresh shell in the directory and exits without running anything. Call deploy.ps1 directly via PowerShell as shown above.
