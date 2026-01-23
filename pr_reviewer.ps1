param (
    [string]$OpenAIEndpoint = $env:AZURE_OPENAI_ENDPOINT,
    [string]$OpenAIKey = $env:AZURE_OPENAI_KEY,
    [string]$OpenAIDeployment = "gpt-4",
    [string]$ContextFilePath = "project_context.md"
)

# -------------------------------------------------------------------------
# 1. Environment & Setup
# -------------------------------------------------------------------------
$orgUrl = $env:SYSTEM_COLLECTIONURI
$project = $env:SYSTEM_TEAMPROJECT
$repoId = $env:BUILD_REPOSITORY_ID
$prId = $env:SYSTEM_PULLREQUEST_PULLREQUESTID
$accessToken = $env:SYSTEM_ACCESSTOKEN

if (-not $prId) {
    Write-Host "##vso[task.logissue type=warning]Not a Pull Request build. Skipping review."
    exit 0
}

$headers = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# -------------------------------------------------------------------------
# 2. Get Project Context
# -------------------------------------------------------------------------
$contextContent = ""
if (Test-Path $ContextFilePath) {
    Write-Host "Reading project context from $ContextFilePath..."
    $contextContent = Get-Content -Path $ContextFilePath -Raw
} else {
    Write-Host "##vso[task.logissue type=warning]Context file $ContextFilePath not found using default generic context."
    $contextContent = "This is a software project. Review the code for standard best practices, bugs, and security issues."
}

# -------------------------------------------------------------------------
# 3. Get Code Changes (Git Diff)
# -------------------------------------------------------------------------
# Azure Pipelines usually fetches a merge commit. We want diff against target.
$targetBranch = $env:SYSTEM_PULLREQUEST_TARGETBRANCH -replace 'refs/heads/', 'origin/'
Write-Host "Calculating diff against $targetBranch..."

# Ensure we have the target branch fetched (pipelines sometimes do shallow fetch)
git fetch origin $env:SYSTEM_PULLREQUEST_TARGETBRANCHNumber 2>&1 | Out-Null

$diff = git diff $targetBranch -- . ':(exclude)package-lock.json' ':(exclude)*.lock' | Out-String

if ([string]::IsNullOrWhiteSpace($diff)) {
    Write-Host "No changes detected or empty diff."
    exit 0
}

# Truncate if too huge (basic safety)
if ($diff.Length -gt 15000) {
    $diff = $diff.Substring(0, 15000) + "... [Truncated]"
}

# -------------------------------------------------------------------------
# 4. Construct AI Prompt
# -------------------------------------------------------------------------
$systemPrompt = @"
You are an expert Senior Software Architect and Code Reviewer.
Your goal is to review the following Pull Request code changes and provide actionable, high-quality feedback.

You have access to the 'Project Context' below, which defines the architectural standards, coding guidelines, and security requirements for this specific project.

### Project Context
$contextContent

### Review Instructions
1.  **Analyze**: Compare the code changes (Git Diff) against the 'Project Context' rules.
2.  **Focus Areas**:
    *   **Architecture**: Does this code violate any layered architecture or patterns defined in the context?
    *   **Security**: Look for SQL injection, hardcoded secrets, unvalidated inputs, or insecure data handling.
    *   **Performance**: Identify O(n^2) loops, blocking I/O calls (e.g., .Result), or memory leaks.
    *   **Readability**: Is the code clean, self-documenting, and following standard naming conventions?
3.  **Tone**: Be professional, constructive, and concise. Avoid nitpicking (e.g., missing spaces) unless it violates a strict style guide.
4.  **Format**:
    *   Start with a **Summary** (1-2 sentences).
    *   Use a **Bullet list** for specific issues.
    *   For each issue, cite the file name and line number if possible.
    *   If the code is excellent and meets all standards, just say "LGTM: [Reason]" and nothing else.

### Important
*   Do NOT halluncinate code requiring changes if none are needed.
*   If the diff is truncated, review what is visible.
"@

$userPrompt = "Here is the git diff of the changes:\n\n$diff"

$payload = @{
    messages = @(
        @{ role = "system"; content = $systemPrompt },
        @{ role = "user"; content = $userPrompt }
    )
    max_tokens = 800
    temperature = 0.7
} | ConvertTo-Json -Depth 5

# -------------------------------------------------------------------------
# 5. Call Azure OpenAI
# -------------------------------------------------------------------------
$url = "$OpenAIEndpoint/openai/deployments/$OpenAIDeployment/chat/completions?api-version=2023-05-15"
$aiHeaders = @{ "api-key" = $OpenAIKey; "Content-Type" = "application/json" }

Write-Host "Sending request to Azure OpenAI..."
try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $aiHeaders -Body $payload
    $reviewComment = $response.choices[0].message.content
}
catch {
    Write-Error "Failed to call OpenAI: $_"
    exit 1
}

# -------------------------------------------------------------------------
# 6. Post Comment to Azure DevOps PR
# -------------------------------------------------------------------------
Write-Host "Posting review to PR #$prId..."

$threadBaseUrl = "$orgUrl$project/_apis/git/repositories/$repoId/pullRequests/$prId/threads?api-version=6.0"

$commentPayload = @{
    comments = @(
        @{
            parentCommentId = 0
            content = $reviewComment
            commentType = "text"
        }
    )
    status = "active"
} | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri $threadBaseUrl -Method Post -Headers $headers -Body $commentPayload
    Write-Host "Successfully posted AI review."
}
catch {
    Write-Error "Failed to post comment to ADO: $_"
    exit 1
}
