param([string]$OutPath)
$ErrorActionPreference = 'Stop'

# Fill colors (Excel BGR longs) per spec v0.4 legend
$YELLOW = 65535      # FFFF00 inputs
$BLUE   = 15123099   # 9BC2E6 assumptions
$GREEN  = 13561798   # C6EFCE formulas
$GRAY   = 14277081   # D9D9D9 final outputs

$FMT_USD  = '$#,##0;-$#,##0'
$FMT_EUR  = '#,##0'
$FMT_RATE = '0.0000'
$FMT_DF   = '0.000000'
$FMT_PCT  = '0.0000%'
$FMT_PCT2 = '0.00%'

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false
$xl.DisplayAlerts = $false
try {
  $wb = $xl.Workbooks.Add()
  while ($wb.Worksheets.Count -lt 9) { $null = $wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
  $names = 'Cover','Legend-Key','Inputs','Forward','MoneyMarket','Option','Sensitivity','Checks','Notes & Assumptions'
  for ($i = 0; $i -lt 9; $i++) { $wb.Worksheets.Item($i + 1).Name = $names[$i] }
  $ws = @{}; foreach ($n in $names) { $ws[$n] = $wb.Worksheets.Item($n) }

  function Put($sh, $addr, $val, $fmt = $null, $color = $null, $name = $null) {
    $step = 'range'
    try {
      $r = $sh.Range($addr)
      $step = 'value'
      if ($val -is [string]) {
        if ($val.StartsWith('=')) { $r.Formula = [string]$val } else { $r.Value2 = [string]$val }
      } else { $r.Value2 = [double]$val }
      $step = 'format'
      if ($fmt)   { $r.NumberFormat = $fmt }
      $step = 'color'
      if ($color) { $r.Interior.Color = $color }
      $step = 'name'
      if ($name)  { $r.Name = [string]$name }
    } catch { throw "Put failed at $($sh.Name)!$addr step=$step (val=$val, fmt=$fmt, color=$color, name=$name): $_" }
  }
  function Title($sh, $text, $sub = $null) {
    Put $sh 'A1' $text; $sh.Range('A1').Font.Bold = $true; $sh.Range('A1').Font.Size = 14
    if ($sub) { Put $sh 'A2' $sub; $sh.Range('A2').Font.Italic = $true }
  }
  function Header($sh, $addr) { $sh.Range($addr).Font.Bold = $true }

  # ---------- Cover ----------
  $c = $ws['Cover']
  Title $c 'ERP Software Firm - FX Transaction Hedge Model'
  $cover = @(
    @('Scenario', 'Scenario 34: erp-software. EUR 2,900,000 receivable from a Dutch retailer, settling in 91 days'),
    @('Author',   'Vanessa Louie'),
    @('Version',  'Workbook draft built from spec v0.4 (capabilities/fx-hedging/spec.md)'),
    @('Date',     '2026-11-13'),
    @('Purpose',  'Compare no hedge, forward, money-market, and put hedges for the receivable; the call is shown for comparison only.')
  )
  for ($i = 0; $i -lt $cover.Count; $i++) { $r = 3 + $i; Put $c "A$r" $cover[$i][0]; Put $c "B$r" ("'" + $cover[$i][1]) }
  Header $c 'A3:A7'
  Put $c 'A9' 'Data provenance (the only place sources are stored)'; Header $c 'A9'
  Put $c 'A10' 'Indicative placeholder, replaced at Stage 4.'; $c.Range('A10').Font.Italic = $true
  Put $c 'A11' 'Input'; Put $c 'B11' 'Source'; Put $c 'C11' 'Date'; Header $c 'A11:C11'
  $prov = @(
    @('S0_in',  'PrimeXBT, intraday',                       '6 Nov 2026'),
    @('F0_in',  "Scenario's indicative quote (stale)",      'Scenario'),
    @('R_USD',  '3-month CME Term SOFR, global-rates.com',  '5 Nov 2026'),
    @('R_FC',   '3-month Euribor, global-rates.com',        '5 Nov 2026')
  )
  for ($i = 0; $i -lt 4; $i++) { $r = 12 + $i; Put $c "A$r" $prov[$i][0]; Put $c "B$r" $prov[$i][1]; Put $c "C$r" ("'" + $prov[$i][2]) }
  $c.Columns.Item(1).ColumnWidth = 14; $c.Columns.Item(2).ColumnWidth = 90; $c.Columns.Item(3).ColumnWidth = 14

  # ---------- Legend-Key ----------
  $l = $ws['Legend-Key']
  Title $l 'Legend / Key' 'Colors are cell FILLS.'
  $leg = @(
    @($YELLOW, 'Inputs: typed values (Inputs tab), plus the Checks Expected column: "Reference inputs, typed by design."'),
    @($BLUE,   'Assumptions: BASIS, STEP_FRAC, FWD_SOURCE, and the tolerance inputs (TOL_*)'),
    @($GREEN,  'Formulas: every formula that is not a final output'),
    @($GRAY,   'Final outputs: strategy summary block, Sensitivity result columns and winner labels, Checks Result column')
  )
  for ($i = 0; $i -lt 4; $i++) { $r = 4 + $i; $l.Range("A$r").Interior.Color = $leg[$i][0]; Put $l "B$r" $leg[$i][1] }
  $l.Columns.Item(1).ColumnWidth = 8; $l.Columns.Item(2).ColumnWidth = 110

  # ---------- Inputs ----------
  $in = $ws['Inputs']
  Title $in 'Inputs (§2.1)' 'All inputs are named ranges. Sources: see the Cover provenance block.'
  foreach ($p in @(@('A3','Name'),@('B3','Description'),@('C3','Value'),@('D3','Unit'),@('E3','Source'))) { Put $in $p[0] $p[1] }
  Header $in 'A3:E3'
  $rows = @(
    @(4,  'FC_AMT',     'EUR receivable',                                2900000,    $FMT_EUR,  $YELLOW, 'EUR',              'Fixed by scenario'),
    @(5,  'S0_in',      'Spot at inception',                             1.1157,     $FMT_RATE, $YELLOW, 'USD per EUR',      '=Cover!B12&" ("&Cover!C12&")"'),
    @(6,  'F0_in',      '91-day forward (quoted)',                       1.1653,     $FMT_RATE, $YELLOW, 'USD per EUR',      '=Cover!B13&" ("&Cover!C13&")"'),
    @(7,  'R_USD',      'USD rate to settlement',                        0.040669,   $FMT_PCT,  $YELLOW, 'Annual, ACT/360',  '=Cover!B14&" ("&Cover!C14&")"'),
    @(8,  'R_FC',       'EUR rate to settlement',                        0.02812,    $FMT_PCT,  $YELLOW, 'Annual, ACT/360',  '=Cover!B15&" ("&Cover!C15&")"'),
    @(9,  'T_DAYS',     'Days to settlement',                            91,         '0',       $YELLOW, 'Days',             'Fixed by scenario'),
    @(10, 'BASIS',      'Day-count denominator (assumption)',            360,        '0',       $BLUE,   'Days',             'Both legs ACT/360'),
    @(11, 'K_PUT',      'Put strike (= S0_in, at the money)',            '=S0_in',   $FMT_RATE, $GREEN,  'USD per EUR',      'Formula'),
    @(12, 'K_CALL',     'Call strike (= S0_in, at the money)',           '=S0_in',   $FMT_RATE, $GREEN,  'USD per EUR',      'Formula'),
    @(13, 'PREM_PUT',   'Put premium per 1 EUR',                         0.0147,     $FMT_RATE, $YELLOW, 'USD',              'Fixed by scenario'),
    @(14, 'PREM_CALL',  'Call premium per 1 EUR (comparison only)',      0.0199,     $FMT_RATE, $YELLOW, 'USD',              'Fixed by scenario'),
    @(15, 'STEP_FRAC',  'Sensitivity grid step (assumption)',            0.01,       '0%',      $BLUE,   '%',                'Fixed by design'),
    @(16, 'FWD_SOURCE', 'Forward-source toggle: "Quoted" or "Implied"',  'Quoted',   '@',       $BLUE,   'Text',             'Fixed by design (default "Quoted")'),
    @(17, 'TOL_USD',    'Checks tolerance: USD and EUR amounts',         1,          '0',       $BLUE,   'USD / EUR',        'Fixed by design'),
    @(18, 'TOL_FACTOR', 'Checks tolerance: growth factors',              0.000001,   '0.000000',$BLUE,   'Factor',           'Fixed by design'),
    @(19, 'TOL_RATE',   'Checks tolerance: exchange rates',              0.0001,     $FMT_RATE, $BLUE,   'USD per EUR',      'Fixed by design'),
    @(20, 'TOL_PARITY', 'Checks tolerance: parity gap, % of USD_MM',     0.0005,     $FMT_PCT2, $BLUE,   '%',                'Fixed by design'),
    @(21, 'TOL_EXACT',  'Checks tolerance: exact checks',                0,          '0',       $BLUE,   'n/a',              'Fixed by design')
  )
  foreach ($x in $rows) {
    $r = $x[0]; Put $in "A$r" $x[1]; Put $in "B$r" $x[2]
    Put $in "C$r" $x[3] $x[4] $x[5] $x[1]
    Put $in "D$r" $x[6]; Put $in "E$r" $x[7]
  }
  $null = $in.Range('C16').Validation.Delete()
  $in.Range('C16').Validation.Add(3, 1, 1, 'Quoted,Implied')
  Put $in 'A23' 'Derived values (§2.2, §4 Step 1)'; Header $in 'A23'
  Put $in 'A24' 'DF_USD';       Put $in 'B24' 'USD growth factor to settlement';  Put $in 'C24' '=1+R_USD*T_DAYS/BASIS'          $FMT_DF  $GREEN 'DF_USD'
  Put $in 'A25' 'DF_FC';        Put $in 'B25' 'EUR growth factor to settlement';  Put $in 'C25' '=1+R_FC*T_DAYS/BASIS'           $FMT_DF  $GREEN 'DF_FC'
  Put $in 'A26' 'FV_PREM_PUT';  Put $in 'B26' 'Put premium at settlement (cost)'; Put $in 'C26' '=-PREM_PUT*FC_AMT*DF_USD'       $FMT_USD $GREEN 'FV_PREM_PUT'
  Put $in 'A27' 'FV_PREM_CALL'; Put $in 'B27' 'Call premium at settlement (cost)';Put $in 'C27' '=-PREM_CALL*FC_AMT*DF_USD'      $FMT_USD $GREEN 'FV_PREM_CALL'
  $in.Columns.Item(1).ColumnWidth = 14; $in.Columns.Item(2).ColumnWidth = 44; $in.Columns.Item(3).ColumnWidth = 14
  $in.Columns.Item(4).ColumnWidth = 16; $in.Columns.Item(5).ColumnWidth = 60

  # ---------- MoneyMarket ----------
  $mm = $ws['MoneyMarket']
  Title $mm 'Money-market hedge (§4 Step 3)' 'Three explicit steps, then the CIP-implied forward and the parity check.'
  Put $mm 'A4'  'Step 1: Borrow EUR today (FC_AMT / DF_FC)';         Put $mm 'C4'  '=FC_AMT/DF_FC'   $FMT_EUR  $GREEN 'EUR_BORROWED'
  Put $mm 'A5'  'Step 2: Convert at spot (USD)';                     Put $mm 'C5'  '=EUR_BORROWED*S0_in' $FMT_USD $GREEN 'USD_AT_SPOT'
  Put $mm 'A6'  'Step 3: Invest USD to maturity = USD_MM';           Put $mm 'C6'  '=USD_AT_SPOT*DF_USD' $FMT_USD $GREEN 'USD_MM'
  Put $mm 'A8'  'F_IMPLIED (CIP-implied forward)';                   Put $mm 'C8'  '=S0_in*DF_USD/DF_FC' $FMT_RATE $GREEN 'F_IMPLIED'
  Put $mm 'A9'  'USD at the quoted forward (FC_AMT x F0_in)';        Put $mm 'C9'  '=FC_AMT*F0_in'   $FMT_USD  $GREEN
  Put $mm 'A10' 'PARITY_GAP (USD)';                                  Put $mm 'C10' '=C9-USD_MM'      $FMT_USD  $GREEN 'PARITY_GAP'
  Put $mm 'A11' 'PARITY_GAP (% of USD_MM)';                          Put $mm 'C11' '=PARITY_GAP/USD_MM' $FMT_PCT2 $GREEN 'PARITY_GAP_PCT'
  Put $mm 'A12' 'Parity check (within TOL_PARITY)';                  Put $mm 'C12' '=IF(ABS(PARITY_GAP_PCT)<=TOL_PARITY,"PASS","FAIL")' $null $GREEN
  Put $mm 'A13' 'The parity check always uses the quoted F0_in, never F_USED, so the FWD_SOURCE toggle cannot hide the gap.'
  $mm.Range('A13').Font.Italic = $true
  $mm.Columns.Item(1).ColumnWidth = 48; $mm.Columns.Item(3).ColumnWidth = 16

  # ---------- Forward ----------
  $fw = $ws['Forward']
  Title $fw 'Forward hedge (§4 Step 2)' 'Placeholder: forward-based outputs use the stale scenario forward until Stage 4.'
  Put $fw 'A4' 'Forward source selected (FWD_SOURCE)'; Put $fw 'C4' '=FWD_SOURCE' $null $GREEN
  Put $fw 'A5' 'F_USED';                               Put $fw 'C5' '=IF(FWD_SOURCE="Implied",F_IMPLIED,F0_in)' $FMT_RATE $GREEN 'F_USED'
  Put $fw 'A6' 'USD_FWD (FC_AMT x F_USED), locked in at t0'; Put $fw 'C6' '=FC_AMT*F_USED' $FMT_USD $GREEN 'USD_FWD'
  $fw.Columns.Item(1).ColumnWidth = 44; $fw.Columns.Item(3).ColumnWidth = 16

  # ---------- Sensitivity: grid S_T first (Option tab reads it) ----------
  $se = $ws['Sensitivity']
  Title $se 'Sensitivity (§4 Steps 5-6, §7)'
  $hdr = 'i','S_T','No hedge','Forward','Money market','Option (put)','Hedge profit: Forward','Hedge profit: Money market','Hedge profit: Put','Overall winner','Best active hedge'
  $cols = 'B','C','D','E','F','G','H','I','J','K','L'
  Put $se 'A18' 'Core grid: S0_in x (1 + i x STEP_FRAC), i = -5 to +5 (11 rows)'; Header $se 'A18'
  for ($k = 0; $k -lt 11; $k++) { Put $se "$($cols[$k])19" $hdr[$k]; Put $se "$($cols[$k])33" $hdr[$k] }
  Header $se 'B19:L19'; Header $se 'B33:L33'
  Put $se 'A32' 'Extension block (not part of the core grid or the grid check): +6% and +7%'; Header $se 'A32'
  $core = 20..30; $ext = 34..35
  foreach ($r in $core) {
    Put $se "B$r" '=ROW()-ROW($B$25)' '0' $GREEN
    Put $se "C$r" "=S0_in*(1+B$r*STEP_FRAC)" $FMT_RATE $GREEN
  }
  foreach ($r in $ext) {
    Put $se "B$r" "=MAX(`$B`$20:`$B`$30)+ROWS(`$B`$34:B$r)" '0' $GREEN
    Put $se "C$r" "=S0_in*(1+B$r*STEP_FRAC)" $FMT_RATE $GREEN
  }
  $null = $wb.Names.Add('S_T_grid', "='Sensitivity'!`$C`$20:`$C`$30")

  # ---------- Option ----------
  $op = $ws['Option']
  Title $op 'Option hedge (§4 Step 4): put on EUR'
  Put $op 'A3' 'K_PUT';                                Put $op 'C3' '=K_PUT'                $FMT_RATE $GREEN
  Put $op 'A4' 'Put premium paid today (USD)';         Put $op 'C4' '=PREM_PUT*FC_AMT'      $FMT_USD  $GREEN 'PREM_PUT_USD'
  Put $op 'A5' 'FV_PREM_PUT (premium at settlement)';  Put $op 'C5' '=FV_PREM_PUT'          $FMT_USD  $GREEN
  Put $op 'A6' 'BREAKEVEN_PUT_FWD (F_USED - FV_PREM_PUT / FC_AMT)'; Put $op 'C6' '=F_USED-FV_PREM_PUT/FC_AMT' $FMT_RATE $GREEN 'BREAKEVEN_PUT_FWD'
  Put $op 'B8' 'S_T'; Put $op 'C8' 'Put intrinsic payoff (USD)'; Put $op 'D8' 'USD_PUT = MAX(S_T, K_PUT) x FC_AMT + FV_PREM_PUT'; Header $op 'B8:D8'
  $opRow = 9
  foreach ($r in $core) {
    Put $op "B$opRow" "=Sensitivity!C$r" $FMT_RATE $GREEN
    Put $op "C$opRow" "=MAX(K_PUT-B$opRow,0)*FC_AMT" $FMT_USD $GREEN
    Put $op "D$opRow" "=MAX(B$opRow,K_PUT)*FC_AMT+FV_PREM_PUT" $FMT_USD $GREEN
    $opRow++
  }
  $null = $wb.Names.Add('USD_PUT', "='Option'!`$D`$9:`$D`$19")
  Put $op 'A21' 'Extension rows (+6%, +7%)'; Header $op 'A21'
  $opRow = 22
  foreach ($r in $ext) {
    Put $op "B$opRow" "=Sensitivity!C$r" $FMT_RATE $GREEN
    Put $op "C$opRow" "=MAX(K_PUT-B$opRow,0)*FC_AMT" $FMT_USD $GREEN
    Put $op "D$opRow" "=MAX(B$opRow,K_PUT)*FC_AMT+FV_PREM_PUT" $FMT_USD $GREEN
    $opRow++
  }
  Put $op 'A26' 'Comparison only: a call does not hedge a EUR receivable.'; $op.Range('A26').Font.Bold = $true
  Put $op 'A27' 'K_CALL';                               Put $op 'C27' '=K_CALL'              $FMT_RATE $GREEN
  Put $op 'A28' 'Call premium paid today (USD)';        Put $op 'C28' '=PREM_CALL*FC_AMT'    $FMT_USD  $GREEN 'PREM_CALL_USD'
  Put $op 'A29' 'FV_PREM_CALL (premium at settlement)'; Put $op 'C29' '=FV_PREM_CALL'        $FMT_USD  $GREEN
  Put $op 'B31' 'S_T'; Put $op 'C31' 'CALL_NET = MAX(S_T - K_CALL, 0) x FC_AMT + FV_PREM_CALL'; Put $op 'D31' 'USD_CALL = S_T x FC_AMT + CALL_NET'; Header $op 'B31:D31'
  $opRow = 32
  foreach ($r in $core) {
    Put $op "B$opRow" "=Sensitivity!C$r" $FMT_RATE $GREEN
    Put $op "C$opRow" "=MAX(B$opRow-K_CALL,0)*FC_AMT+FV_PREM_CALL" $FMT_USD $GREEN
    Put $op "D$opRow" "=B$opRow*FC_AMT+C$opRow" $FMT_USD $GREEN
    $opRow++
  }
  $null = $wb.Names.Add('CALL_NET', "='Option'!`$C`$32:`$C`$42")
  $null = $wb.Names.Add('USD_CALL', "='Option'!`$D`$32:`$D`$42")
  $op.Columns.Item(1).ColumnWidth = 50; $op.Columns.Item(2).ColumnWidth = 10
  $op.Columns.Item(3).ColumnWidth = 30; $op.Columns.Item(4).ColumnWidth = 44

  # ---------- Sensitivity: result columns ----------
  $map = @{}; for ($k = 0; $k -lt 11; $k++) { $map[$core[$k]] = 9 + $k }; $map[34] = 22; $map[35] = 23
  foreach ($r in ($core + $ext)) {
    $h = if ($r -ge 34) { 33 } else { 19 }
    Put $se "D$r" "=C$r*FC_AMT"          $FMT_USD $GRAY
    Put $se "E$r" '=USD_FWD'             $FMT_USD $GRAY
    Put $se "F$r" '=USD_MM'              $FMT_USD $GRAY
    Put $se "G$r" "=Option!D$($map[$r])" $FMT_USD $GRAY
    Put $se "H$r" "=E$r-D$r"             $FMT_USD $GRAY
    Put $se "I$r" "=F$r-D$r"             $FMT_USD $GRAY
    Put $se "J$r" "=G$r-D$r"             $FMT_USD $GRAY
    Put $se "K$r" "=INDEX(`$D`$$h`:`$G`$$h,MATCH(MAX(D$r`:G$r),D$r`:G$r,0))" $null $GRAY
    Put $se "L$r" "=INDEX(`$E`$$h`:`$G`$$h,MATCH(MAX(E$r`:G$r),E$r`:G$r,0))" $null $GRAY
  }
  $null = $wb.Names.Add('USD_NO_HEDGE', "='Sensitivity'!`$D`$20:`$D`$30")

  # Strategy summary block (gray final outputs)
  Put $se 'B3' 'Strategy summary (forward-based figures are placeholders until Stage 4)'; Header $se 'B3'
  $base = 'MATCH(S0_in,S_T_grid,0)'
  $sum = @(
    @(4,  'Forward source (FWD_SOURCE)',        '=FWD_SOURCE',              $null),
    @(5,  'USD_FWD',                            '=USD_FWD',                 $FMT_USD),
    @(6,  'USD_MM',                             '=USD_MM',                  $FMT_USD),
    @(7,  'F_IMPLIED',                          '=F_IMPLIED',               $FMT_RATE),
    @(8,  'PARITY_GAP (USD)',                   '=PARITY_GAP',              $FMT_USD),
    @(9,  'PARITY_GAP (% of USD_MM)',           '=PARITY_GAP_PCT',          $FMT_PCT2),
    @(10, 'USD_BASE: No hedge (S_T = S0_in)',   "=INDEX(USD_NO_HEDGE,$base)", $FMT_USD),
    @(11, 'USD_BASE: Forward',                  "=INDEX(`$E`$20:`$E`$30,$base)", $FMT_USD),
    @(12, 'USD_BASE: Money market',             "=INDEX(`$F`$20:`$F`$30,$base)", $FMT_USD),
    @(13, 'USD_BASE: Option (put)',             "=INDEX(USD_PUT,$base)",    $FMT_USD),
    @(14, 'USD_FLOOR_PUT (minimum put proceeds)','=MIN(USD_PUT)',           $FMT_USD),
    @(15, 'BREAKEVEN_PUT_FWD',                  '=BREAKEVEN_PUT_FWD',       $FMT_RATE),
    @(16, 'Euro rise needed to reach break-even','=BREAKEVEN_PUT_FWD/S0_in-1', $FMT_PCT2)
  )
  foreach ($x in $sum) { Put $se "B$($x[0])" $x[1]; Put $se "E$($x[0])" $x[2] $x[3] $GRAY }
  $null = $wb.Names.Add('USD_FLOOR_PUT', "='Sensitivity'!`$E`$14")
  $se.Columns.Item(1).ColumnWidth = 4; $se.Columns.Item(2).ColumnWidth = 6
  foreach ($col in 'C','D','E','F','G','H','I','J') { $se.Columns.Item($col).ColumnWidth = 15 }
  $se.Columns.Item('K').ColumnWidth = 16; $se.Columns.Item('L').ColumnWidth = 18
  $se.Range('B4:B16').WrapText = $false

  # Charts: core (+/-5%) and extended (core + extension)
  function AddChart($left, $top, $width, $height, $title, $xRef, $refs) {
    $shape = $se.Shapes.AddChart2(-1, 74, $left, $top, $width, $height)
    $script:lastChart = $shape.Chart
    $ch = $shape.Chart
    while ($ch.SeriesCollection().Count -gt 0) { $ch.SeriesCollection(1).Delete() }
    $labels = 'No hedge','Forward','Money market','Option (put)'
    for ($k = 0; $k -lt 4; $k++) {
      $s = $ch.SeriesCollection().NewSeries()
      $s.Name = $labels[$k]; $s.XValues = $xRef; $s.Values = $refs[$k]
    }
    $ch.HasTitle = $true; $ch.ChartTitle.Text = $title
    $ax = $ch.Axes(1); $ax.HasTitle = $true; $ax.AxisTitle.Text = 'Settlement spot S_T (USD per EUR)'
    $ay = $ch.Axes(2); $ay.HasTitle = $true; $ay.AxisTitle.Text = 'USD proceeds'
    $ax.MinimumScale = 1.05
  }
  $top = $se.Range('N3').Top; $left = $se.Range('N3').Left
  AddChart $left $top 620 330 'USD proceeds vs. settlement spot (core grid, -5% to +5%)' "='Sensitivity'!`$C`$20:`$C`$30" @(
    "='Sensitivity'!`$D`$20:`$D`$30", "='Sensitivity'!`$E`$20:`$E`$30", "='Sensitivity'!`$F`$20:`$F`$30", "='Sensitivity'!`$G`$20:`$G`$30")
  AddChart $left ($top + 345) 460 260 'Extended grid: put break-even vs forward' "=('Sensitivity'!`$C`$20:`$C`$30,'Sensitivity'!`$C`$34:`$C`$35)" @(
    "=('Sensitivity'!`$D`$20:`$D`$30,'Sensitivity'!`$D`$34:`$D`$35)", "=('Sensitivity'!`$E`$20:`$E`$30,'Sensitivity'!`$E`$34:`$E`$35)",
    "=('Sensitivity'!`$F`$20:`$F`$30,'Sensitivity'!`$F`$34:`$F`$35)", "=('Sensitivity'!`$G`$20:`$G`$30,'Sensitivity'!`$G`$34:`$G`$35)")
  # Break-even marker: one point at (BREAKEVEN_PUT_FWD, USD_FWD), where put proceeds equal the forward's
  $be = $script:lastChart.SeriesCollection().NewSeries()
  $be.Name = 'Put break-even (BREAKEVEN_PUT_FWD)'
  $be.XValues = "='Sensitivity'!`$E`$15"; $be.Values = "='Sensitivity'!`$E`$5"
  $be.ChartType = -4169; $be.MarkerStyle = 8; $be.MarkerSize = 9
  $be.Points(1).HasDataLabel = $true
  $be.Points(1).DataLabel.ShowValue = $false; $be.Points(1).DataLabel.ShowCategoryName = $true

  # ---------- Checks ----------
  $ck = $ws['Checks']
  Title $ck 'Checks (§5.2, §6.3)' 'Expected column: Reference inputs, typed by design. Failing checks show FAIL; none are forced to pass.'
  Put $ck 'A4' 'Checks failing'; Header $ck 'A4'
  foreach ($p in @(@('A6','Check'),@('B6','Expected'),@('C6','Calculated'),@('D6','Difference'),@('E6','Tolerance'),@('F6','Result'))) { Put $ck $p[0] $p[1] }
  Header $ck 'A6:F6'
  $checks = @(
    @('Parity: PARITY_GAP as % of USD_MM (expected FAIL at placeholders)', 0,        '=PARITY_GAP_PCT',                           'TOL_PARITY', $FMT_PCT),
    @('Kink: USD_PUT at S_T = K_PUT',                                    3192462,  '=INDEX(USD_PUT,MATCH(K_PUT,S_T_grid,0))',    'TOL_USD',    $FMT_USD),
    @('Constancy: forward proceeds, max - min across grid',              0,        '=MAX(Sensitivity!E20:E30)-MIN(Sensitivity!E20:E30)', 'TOL_EXACT', $FMT_USD),
    @('Constancy: money-market proceeds, max - min across grid',         0,        '=MAX(Sensitivity!F20:F30)-MIN(Sensitivity!F20:F30)', 'TOL_EXACT', $FMT_USD),
    @('Grid: core row count',                                            11,       '=COUNT(S_T_grid)',                            'TOL_EXACT',  '0'),
    @('Grid: centre row equals S0_in (median - S0_in)',                  0,        '=MEDIAN(S_T_grid)-S0_in',                     'TOL_EXACT',  $FMT_RATE),
    @('Grid: symmetric about S0_in ((min + max)/2 - S0_in)',             0,        '=AVERAGE(MIN(S_T_grid),MAX(S_T_grid))-S0_in', 'TOL_RATE',   $FMT_RATE),
    @('§5.1 Base case: No hedge',                                        3235530,  '=Sensitivity!E10',                            'TOL_USD',    $FMT_USD),
    @('§5.1 Base case: Forward',                                         3379370,  '=Sensitivity!E11',                            'TOL_USD',    $FMT_USD),
    @('§5.1 Base case: Money market',                                    3245721,  '=Sensitivity!E12',                            'TOL_USD',    $FMT_USD),
    @('§5.1 Base case: Option (put)',                                    3192462,  '=Sensitivity!E13',                            'TOL_USD',    $FMT_USD),
    @('§5.1 Hedge profit: Forward',                                      143840,   "=INDEX(Sensitivity!H20:H30,$base)",           'TOL_USD',    $FMT_USD),
    @('§5.1 Hedge profit: Money market',                                 10191,    "=INDEX(Sensitivity!I20:I30,$base)",           'TOL_USD',    $FMT_USD),
    @('§5.1 Hedge profit: Option (put)',                                 -43068,   "=INDEX(Sensitivity!J20:J30,$base)",           'TOL_USD',    $FMT_USD),
    @('§5.1 DF_USD',                                                     1.010280, '=DF_USD',                                     'TOL_FACTOR', $FMT_DF),
    @('§5.1 DF_FC',                                                      1.007108, '=DF_FC',                                      'TOL_FACTOR', $FMT_DF),
    @('§5.1 EUR borrowed',                                               2879532,  '=EUR_BORROWED',                               'TOL_USD',    $FMT_EUR),
    @('§5.1 USD at spot',                                                3212694,  '=USD_AT_SPOT',                                'TOL_USD',    $FMT_USD),
    @('§5.1 F_IMPLIED',                                                  1.1192,   '=F_IMPLIED',                                  'TOL_RATE',   $FMT_RATE),
    @('§5.1 PARITY_GAP (USD)',                                           133649,   '=PARITY_GAP',                                 'TOL_USD',    $FMT_USD),
    @('§5.1 Put premium paid',                                           42630,    '=PREM_PUT_USD',                               'TOL_USD',    $FMT_USD),
    @('§5.1 FV_PREM_PUT',                                                -43068,   '=FV_PREM_PUT',                                'TOL_USD',    $FMT_USD),
    @('§5.1 USD_FLOOR_PUT',                                              3192462,  '=USD_FLOOR_PUT',                              'TOL_USD',    $FMT_USD),
    @('§5.1 BREAKEVEN_PUT_FWD',                                          1.1802,   '=BREAKEVEN_PUT_FWD',                          'TOL_RATE',   $FMT_RATE),
    @('§5.1 Call premium paid',                                          57710,    '=PREM_CALL_USD',                              'TOL_USD',    $FMT_USD),
    @('§5.1 FV_PREM_CALL',                                               -58303,   '=FV_PREM_CALL',                               'TOL_USD',    $FMT_USD),
    @('§5.1 USD_CALL at S_T = S0_in (comparison only)',                  3177227,  "=INDEX(USD_CALL,$base)",                      'TOL_USD',    $FMT_USD)
  )
  $r = 7
  foreach ($x in $checks) {
    Put $ck "A$r" $x[0]
    Put $ck "B$r" $x[1] $x[4] $YELLOW
    Put $ck "C$r" $x[2] $x[4] $GREEN
    Put $ck "D$r" "=C$r-B$r" $x[4] $GREEN
    Put $ck "E$r" "=$($x[3])" $x[4] $GREEN
    Put $ck "F$r" "=IF(ABS(D$r)<=E$r,`"PASS`",`"FAIL`")" $null $GRAY
    $r++
  }
  $last = $r - 1
  Put $ck 'C4' "=COUNTIF(F7:F$last,`"FAIL`")" '0' $GRAY
  $ck.Columns.Item(1).ColumnWidth = 62
  foreach ($col in 'B','C','D','E') { $ck.Columns.Item($col).ColumnWidth = 16 }
  $ck.Columns.Item('F').ColumnWidth = 10

  # ---------- Notes & Assumptions ----------
  $nt = $ws['Notes & Assumptions']
  Title $nt 'Notes & Assumptions (§3, §8)' 'Sources: see the Cover provenance block (Cover!A9).'
  $notes = @(
    'Quote convention: USD per EUR; a higher quote means the euro has strengthened.',
    'Horizon: single maturity, T_DAYS = 91.',
    'Day count: simple interest, r x T_DAYS / BASIS. 3-month Term SOFR and 3-month Euribor are both ACT/360, so BASIS = 360 is exact.',
    'Parity: the money-market hedge should replicate the forward under covered interest parity. A gap larger than rounding is a finding about the inputs.',
    'Known placeholder problem: the scenario forward (1.1653) sits about 4% above the CIP-implied forward, so the parity check is expected to FAIL until Stage 4.',
    'Option premiums are paid upfront in USD per 1 EUR (no multiplier), treated as negative cash flows carried forward at R_USD.',
    'The call is calculated for comparison only; it does not hedge a EUR receivable and is excluded from the winner labels.',
    'Excluded: counterparty and credit risk, transaction costs and bid-ask spreads, tax and hedge accounting.',
    'Scenario construction: S_T varies deterministically across the grid; no probabilities and no volatility model.',
    'Limitations: static full-notional hedge; premiums are scenario inputs, not model prices; forward is a stale placeholder until Stage 4.'
  )
  for ($i = 0; $i -lt $notes.Count; $i++) { Put $nt "A$(4 + $i)" ("- " + $notes[$i]) }
  $nt.Columns.Item(1).ColumnWidth = 150

  $wb.Worksheets.Item('Cover').Activate()
  $xl.CalculateFull()

  # ---------- Self-audit ----------
  $errs = @()
  foreach ($n in $names) {
    foreach ($cell in $ws[$n].UsedRange.Cells) {
      if ($cell.Text -like '#*') { $errs += "$n!$($cell.Address($false,$false)) = $($cell.Text)" }
    }
  }
  "ERROR CELLS: $($errs.Count)"; $errs
  "NAMES: " + (($wb.Names | ForEach-Object { $_.Name }) -join ', ')
  "--- Checks ---"
  for ($i = 7; $i -le $last; $i++) {
    "{0} | exp {1} | calc {2} | diff {3} | tol {4} | {5}" -f $ck.Range("A$i").Text, $ck.Range("B$i").Text, $ck.Range("C$i").Text, $ck.Range("D$i").Text, $ck.Range("E$i").Text, $ck.Range("F$i").Text
  }
  "Failing: " + $ck.Range('C4').Text
  "--- Sensitivity ---"
  foreach ($row in (20..30 + 34..35)) {
    ($cols | ForEach-Object { $se.Range("$_$row").Text }) -join ' | '
  }

  $wb.SaveAs($OutPath, 51)
  $wb.Close($false)
}
finally {
  $xl.Quit()
  [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl)
}
