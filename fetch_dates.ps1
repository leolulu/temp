# 设置起始日期和结束日期（从今天开始到十天前）
$startDate = Get-Date
$endDate = (Get-Date).AddDays(-10)

# 初始化一个空数组用于存储 JSON 数据
$jsonArray = @()

# 循环请求 URL
while ($startDate -gt $endDate) {
    # 格式化日期
    $formattedDate = $startDate.ToString("yyyy-MM-dd")
    
    # 输出当前 formattedDate
    Write-Host "当前日期：$formattedDate"

    # 构建 URL
    $url = "https://timor.tech/api/holiday/info/$formattedDate"
    
    # 请求 URL 并解析 JSON 数据
    $jsonResponse = Invoke-WebRequest -Uri $url | ConvertFrom-Json

    # 根据 jsonResponse.type.type 的值判断 is_workday 的值
    $is_workday = ($jsonResponse.type.type -eq 0 -or $jsonResponse.type.type -eq 3) -and ($jsonResponse.type.week -ne 6 -and $jsonResponse.type.week -ne 7)

    # 分解 formattedDate 为年、月、日
    $year, $month, $day = $formattedDate.Split('-')

    # 移除月份和日期前面的 0
    $year = [int]$year
	$month = [int]$month
    $day = [int]$day

    # 在 jsonResponse 中添加键值对
    $jsonResponse | Add-Member -MemberType NoteProperty -Name "date" -Value $formattedDate
    $jsonResponse | Add-Member -MemberType NoteProperty -Name "is_workday" -Value $is_workday
    $jsonResponse | Add-Member -MemberType NoteProperty -Name "year" -Value $year
    $jsonResponse | Add-Member -MemberType NoteProperty -Name "month" -Value $month
    $jsonResponse | Add-Member -MemberType NoteProperty -Name "day" -Value $day

    # 将解析后的 JSON 数据添加到数组中
    $jsonArray += $jsonResponse

    # 计算前一天的日期
    $startDate = $startDate.AddDays(-1)

    # 等待 3 秒钟
    Start-Sleep -Seconds 2
}

# 将 JSON 数组保存到本地文件，使用 UTF-8 编码
$allDaysInfoPath = Join-Path -Path (Get-Location) -ChildPath "all_days_info.json"
$jsonArray | ConvertTo-Json -Compress | Set-Content -Path $allDaysInfoPath -Encoding UTF8


# 初始化一个新的数组用于存储前两个 is_workday 为 True 的元素
$newJsonArray = @()
$workdayCount = 0

# 遍历 jsonArray 并找到前两个 is_workday 为 True 的元素
foreach ($item in $jsonArray) {
    if ($item.is_workday -eq $true) {
        $newJsonArray += $item
        $workdayCount++
    }

    if ($workdayCount -eq 2) {
        break
    }
}

# 将新的 JSON 数组保存到另一个文件，使用 UTF-8 编码
$firstTwoWorkdaysPath = Join-Path -Path (Get-Location) -ChildPath "first_two_workdays.json"
$newJsonArray | ConvertTo-Json -Compress | Set-Content -Path $firstTwoWorkdaysPath -Encoding UTF8

Write-Host "allDaysInfoPath：$allDaysInfoPath"
Write-Host "firstTwoWorkdaysPath：$firstTwoWorkdaysPath"

# 设置环境变量
[Environment]::SetEnvironmentVariable("ALL_DAYS_INFO_JSON_PATH", $allDaysInfoPath, "User")
[Environment]::SetEnvironmentVariable("FIRST_TWO_WORKDAYS_JSON_PATH", $firstTwoWorkdaysPath, "User")