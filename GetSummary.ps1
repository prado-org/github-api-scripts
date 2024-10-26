# Configurações
$GITHUB_TOKEN = $env:GH_TOKEN
$ORG_NAME = 'prado-org'

# Cabeçalhos de autenticação
$headers = @{
    'Authorization' = "token $GITHUB_TOKEN"
    'Accept' = 'application/vnd.github.v3+json'
}

# Função para obter a próxima URL de paginação
function Get-NextPageUrl {
    param (
        [string]$linkHeader
    )
    if ($linkHeader -match '<(https[^>]+)>; rel="next"') {
        return $matches[1]
    }
    return $null
}

# URL inicial para listar repositórios da organização com paginação de 2 itens por página
$repos_url = "https://api.github.com/orgs/$ORG_NAME/repos?per_page=100"
$all_repos = @()

do {
    Write-Host "----------------------------------------"
    Write-Host "Fetching repositories from: $repos_url"
    $response = Invoke-RestMethod -Uri $repos_url -Headers $headers -Method Get -ResponseHeadersVariable responseHeaders
    $all_repos += $response

    # Obter a próxima URL de paginação
    $repos_url = Get-NextPageUrl -linkHeader $responseHeaders['Link']
} while ($repos_url)

# Inicializar um Hashtable para armazenar os contadores de cada mês
$month_counts = @{}

# Listar todos os repositórios obtidos e contar por mês de criação
foreach ($repo in $all_repos) 
{
    Write-Host "----------------------------------------"
    Write-Host "Repo Name: $($repo.name)"
    Write-Host "Repo URL: $($repo.html_url)"
    Write-Host "Creation Date: $($repo.created_at)"

    # Obter o mês e o ano de criação do repositório
    $creation_month = [datetime]::Parse($repo.created_at).ToString("yyyy-MM")

    # Incrementar o contador do mês correspondente
    if ($month_counts.ContainsKey($creation_month)) {
        $month_counts[$creation_month]++
    } else {
        $month_counts[$creation_month] = 1
    }
}

# Exibir o total de repositórios obtidos
Write-Host "`n----------------------------------------"
Write-Host "Total de Repositórios obtidos: $($all_repos.Count)"

# Exibir a quantidade de repositórios por mês de criação
Write-Host "`n----------------------------------------"
Write-Host "Quantidade de Repositórios por Mês de Criação:"
foreach ($month in $month_counts.Keys) {
    Write-Host "Mes: $month, Quantidade: $($month_counts[$month])"
}

# Listar quantidade de execuções de workflows por repositório
foreach ($repo in $all_repos) {
    # Construir a URL da API para listar as execuções de workflows
    $workflows_url = "https://api.github.com/repos/$($repo.full_name)/actions/runs"

    # Fazer a chamada à API para obter as execuções de workflows
    $workflows_response = Invoke-RestMethod -Uri $workflows_url -Headers $headers -Method Get

    # Obter a quantidade de execuções de workflows
    $workflow_runs_count = $workflows_response.total_count

    # Exibir a quantidade de execuções de workflows
    Write-Host "----------------------------------------"
    Write-Host "Repo Name: $($repo.full_name)"
    Write-Host "Workflow Runs Count: $workflow_runs_count"
}
