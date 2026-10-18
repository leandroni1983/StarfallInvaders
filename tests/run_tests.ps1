# Ejecuta la batería de pruebas automáticas del MVP.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1
#   powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1 -Godot "C:\ruta\a\godot.exe"
#
# Requiere que Godot 4.x esté disponible (en el PATH o indicado en -Godot).

param(
    [string]$Godot = "godot"
)

$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $PSScriptRoot

Write-Host "Godot: $Godot"
& $Godot --version

Write-Host "`n== [1/12] Arranque + gameplay (autostart, ~ waves) =="
& $Godot --path $proj --headless --quit-after 3000 -- autostart

Write-Host "`n== [2/12] Game over + reinicio =="
& $Godot --path $proj --headless --quit-after 600 -- autostart test_gameover

Write-Host "`n== [3/12] Guardado de record en disco =="
& $Godot --path $proj --headless --quit-after 300 -- test_save

Write-Host "`n== [4/12] Pausa congela y reanuda =="
& $Godot --path $proj --headless --quit-after 900 -- autostart test_pause

Write-Host "`n== [5/12] Danza de daño (weaver/grunt resisten 2 impactos y se mueven) =="
& $Godot --path $proj --headless --quit-after 300 -- test_damage

Write-Host "`n== [6/12] Jefe tras el ciclo + dificultad creciente =="
& $Godot --path $proj --headless --quit-after 300 -- test_boss

Write-Host "`n== [7/12] Navecitas del jefe =="
& $Godot --path $proj --headless --quit-after 300 -- test_minions

Write-Host "`n== [8/12] Ciclos: jefe cada 10 oleadas, dificultad y navecitas centradas =="
& $Godot --path $proj --headless --quit-after 300 -- test_cycles

Write-Host "`n== [9/12] Enemigos y patrones nuevos (diver, sniper, formaciones) =="
& $Godot --path $proj --headless --quit-after 300 -- test_enemies

Write-Host "`n== [10/12] Mejoras: arma, escudo, bomba y recogida =="
& $Godot --path $proj --headless --quit-after 300 -- test_powerups

Write-Host "`n== [11/12] Audio: efectos sintetizados, música en bucle y silencio =="
& $Godot --path $proj --headless --quit-after 300 -- test_audio

Write-Host "`n== [12/12] Pantalla de inicio y dificultad (normal/difícil) =="
& $Godot --path $proj --headless --quit-after 300 -- test_difficulty

Write-Host "`nPruebas finalizadas."
