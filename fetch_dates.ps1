# ������ʼ���ںͽ������ڣ��ӽ��쿪ʼ��ʮ��ǰ��
$startDate = Get-Date
$endDate = (Get-Date).AddDays(-10)

# ��ʼ��һ�����������ڴ洢 JSON ����
$jsonArray = @()

# ѭ������ URL
while ($startDate -gt $endDate) {
    # ��ʽ������
    $formattedDate = $startDate.ToString("yyyy-MM-dd")
    
    # �����ǰ formattedDate
    Write-Host "��ǰ���ڣ�$formattedDate"

    # ���� URL
    $url = "https://timor.tech/api/holiday/info/$formattedDate"
    
    # ���� URL ������ JSON ����
    $jsonResponse = Invoke-WebRequest -Uri $url | ConvertFrom-Json

    # ���� jsonResponse.type.type ��ֵ�ж� is_workday ��ֵ
    $is_workday = ($jsonResponse.type.type -eq 0 -or $jsonResponse.type.type -eq 3) -and ($jsonResponse.type.week -ne 6 -and $jsonResponse.type.week -ne 7)

    # �ֽ� formattedDate Ϊ�ꡢ�¡���
    $year, $month, $day = $formattedDate.Split('-')

    # �Ƴ��·ݺ�����ǰ��� 0
    $year = [int]$year
	$month = [int]$month
    $day = [int]$day

    # �� jsonResponse ����Ӽ�ֵ��
    $jsonResponse | Add-Member -MemberType NoteProperty -Name "date" -Value $formattedDate
    $jsonResponse | Add-Member -MemberType NoteProperty -Name "is_workday" -Value $is_workday
    $jsonResponse | Add-Member -MemberType NoteProperty -Name "year" -Value $year
    $jsonResponse | Add-Member -MemberType NoteProperty -Name "month" -Value $month
    $jsonResponse | Add-Member -MemberType NoteProperty -Name "day" -Value $day

    # ��������� JSON ������ӵ�������
    $jsonArray += $jsonResponse

    # ����ǰһ�������
    $startDate = $startDate.AddDays(-1)

    # �ȴ� 3 ����
    Start-Sleep -Seconds 2
}

# �� JSON ���鱣�浽�����ļ���ʹ�� UTF-8 ����
$allDaysInfoPath = Join-Path -Path (Get-Location) -ChildPath "all_days_info.json"
$jsonArray | ConvertTo-Json -Compress | Set-Content -Path $allDaysInfoPath -Encoding UTF8


# ��ʼ��һ���µ��������ڴ洢ǰ���� is_workday Ϊ True ��Ԫ��
$newJsonArray = @()
$workdayCount = 0

# ���� jsonArray ���ҵ�ǰ���� is_workday Ϊ True ��Ԫ��
foreach ($item in $jsonArray) {
    if ($item.is_workday -eq $true) {
        $newJsonArray += $item
        $workdayCount++
    }

    if ($workdayCount -eq 2) {
        break
    }
}

# ���µ� JSON ���鱣�浽��һ���ļ���ʹ�� UTF-8 ����
$firstTwoWorkdaysPath = Join-Path -Path (Get-Location) -ChildPath "first_two_workdays.json"
$newJsonArray | ConvertTo-Json -Compress | Set-Content -Path $firstTwoWorkdaysPath -Encoding UTF8

Write-Host "allDaysInfoPath��$allDaysInfoPath"
Write-Host "firstTwoWorkdaysPath��$firstTwoWorkdaysPath"

# ���û�������
[Environment]::SetEnvironmentVariable("ALL_DAYS_INFO_JSON_PATH", $allDaysInfoPath, "User")
[Environment]::SetEnvironmentVariable("FIRST_TWO_WORKDAYS_JSON_PATH", $firstTwoWorkdaysPath, "User")