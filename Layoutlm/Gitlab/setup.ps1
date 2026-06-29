Write-Host "Activation manuelle de l'environnement Conda layoutlm..."

$condaPath = "C:/Users/HP/anaconda3"
$activateScript = "$condaPath/Scripts/activate"

# Vérifie que le script d'activation existe
if (!(Test-Path $activateScript)) {
    throw "Script d'activation introuvable à $activateScript"
}

# Active layoutlm
& "$activateScript" layoutlm

# Vérifie que Python est accessible
python --version
