<# 
.NAME
    ad-email-senha
.DESCRIPTION
    Envia um email para os Usuários avisando sobre a expiracao da senha do Active Diretory.
.EXAMPLE
    PS C:\> .\ad-email-senha.ps1
.NOTES
    Name: Marcos Henrique
	E-mail: marcos@100security.com.br
#>

$dias_expiracao = 15 # Dias restantes para a expiracao da senha


$usuarios = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} –Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed","mail"  `
| Where-Object {$_.mail -ne $null } `
| Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}},"Mail","SamAccountName" `
| Where-Object {$_.ExpiryDate -lt (Get-Date).AddDays($dias_expiracao) -and $_.ExpiryDate -gt (Get-Date) } 

# Enviar email
$de = "senha@100security.com.br"
$smtp = "192.168.0.67"

foreach($usuario in $usuarios)
{
    $dias = (([DateTime]$usuario.ExpiryDate) - (get-date)).Days
    $para = $usuario.mail
    $usuario = $usuario.SamAccountName
    $dominio = (Get-ADDomain).Forest
    $assunto = "Sua senha expira em $dias dias!"

    $mensagem = @"
A senha do seu usuario ($dominio\$usuario) expira em $dias dias. 

Se voce esta trabalhando remotamente conecte-se na VPN, em seguida pressione as teclas Ctrl + Alt + Del e selecione Alterar uma senha. 

--
Seguranca da Informacao
"@
    
    $para
    $assunto
    $mensagem
    '*' * 80
    Send-MailMessage -Body $mensagem -From $de -SmtpServer $smtp -Subject $assunto -To $para 

}