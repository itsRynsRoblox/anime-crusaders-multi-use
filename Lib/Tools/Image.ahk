#Requires AutoHotkey v2.0

; === Image Paths ===
global Minimize := "Images\minimizeButton.png" 
global Exitbutton := "Images\exitButton.png"
global Disconnected := "Images\disconnected.png"
global Import := "Images\import.png"
global Export := "Images\export.png"

;=== General FindText Text and Buttons ===
ModeCancel:="|<>*134$70.zzzzzzzzzzzzzzzzzzzzzzzzwDzzzzzzzszz0DzzzzzzzXzs0TzzzzzzyDz01zzzzzzzszsDDzzzznz7XzVzw0k3w3k6DyDzU307U60Mzszw0A0A0kEXzXzkkkkkz72DyDz737X7w08zsTwQASATk1XzkMk0lsk33y7z01037X040MDy060ASC0M1Uzy1y8lsy7k73zzzzzzzzzzzzU"
Disconnect:="|<>*154$122.zznzzzzzzzzzzzzzzzzws7szzzzzzzzzzzzzDzzzC0TDzzzzzzzzzzzznzzznb3zzzzzzzzzzzzzwzzzwtwzzzzzzzzzzzzzzDzzzCT7DVy7kz8T8TkzV0S7sHblnUC0k7k3k3k7U060w0tyQsrXMswMwMstsrD7CCCTbCDlyDDDDDCTATnntXnblnkwzblnnnnU3Dww0NwtwQz3DtwQwwws0nzD06TCTDDwlyDDDDDCTwTnnzXnb3nbADXXnnnnXr3wQSsss1ws3UA1wwwww1s31UD0C1zD1y7kzDDDDkzVsS7sHU"
NextLevel:="|<>*113$31.0000000000000000S1s00TVy00MMVU0AAkk063MMA30wAzlUC7sQk73k2M1Vk1A0Ek0640MQ330A01Vk600ks33yMS1UvABUk0a6sQ0H6AD08z3wzwD0w7w0000000000E"
OpenChat:="|<>*154$30.zzzzzzzzzzw000Ds0007s0007s0007s0007s0007s7zs7s7zs7s0007s0007s0z07s1zU7s0007s0007s0007s0007s0007zs07zzy0Tzzz0zzzzVzzzznzzzzzzzU"

; === Anime Crusaders ===
LobbySettings:="|<>*107$25.zzzzzz7zzzXzzrUzzk00Tk00Dw007y003z0Q1zUzUzUzkD0Tw1UDy0k7z0S3zUzUzUzkDUTs00Dw007y003z001zzUzzzszzzwTzzzzzk"
Victory:="|<>*121$155.00000000000000000000000000Ty0DzzU3zkzzzw1zs0zzsDz0Twzy0zzzUTzzzzzwDzy3zzyzz1zvUC3U833k0y000Nw0S600zk670H0A60k6C00Q000r00CA00DU6A1a0QA1UAs00M001w00CM007UCs360Ms30PU00E003k006k0070DUAA0lUC0y000U007000DU00D0S0sQ1r0Q1s003000A000D000C0Q1UM1g1s3k3wDz0Ts1y0C0y0S0E70s3s3k7UDyzy0zk7y0Q1y0y00A0k3U7UC0MDUQ1X0AC0s3A1g00k1U70T0Q1kC0s360sA1k7s3Q03U1UC0q0s3001k6A1UM3UDU6M0603083g1k6003UAM30k7000AM0Q07006M3UC1k70Mk71UC000ks0k0600Qk70A7kC0lU670Q003Uk300C00lUC0TxkQ1XUDw0s00C1U600A01X0S0Tlks330Dk1k00s30A00M0660w041lk660607U00k60M00M0AA1w001nUA6000T0Q0kA0k00k0sM3Q003b0MC000q0w1kM1U01k1Uk6Q00CC0kC003g1s1Uk3001U71UAQ00sQ1UC00SM3s1VU60030A30MS07Us30D03kk6s3X0A003zs7zkTzy0zy0Dzz1zwzz7zs007zUDz0Dzk1zs07zs3zkzw7zU4"
Defeat:="|<>*49$136.00000000000000000000000zzw0Dzzxzzzzzzs1zkDzzz7zzy1zzzzzzzzzzUDzVzzzyM01w6003k00Q0070k66000NU00wM00D001k00Q60AM001a000tU00w007001kM0lU006M001a003k00Q0073U1a000NU003M00D001k00QA06M001a000DU00w007001lk0RU006M3w0S0zzk7zw1zy600rz0TtUDs1s3zz0Tzk7zss03jw1z60lk3U01w1zz00330E61k60M330C007k3zw00AA10Q70M1UAA0s00T003k00lkC0kA1U60kk3U01w00D00360s31k60M330C007k00w00As3UC70M1UAA0s00P003k7zn000MA1U60zU7UDzg00D0TzA001kk60M3w0S0zzk7zw1zzU00330M1U003s0Tz0Tyk7zy000AA1U6000BU00Q1U3000k000Mk60M001a001k60A0030Tw1X0M1U00CM0070M0k00A1zk3A1U6003lU00Q1U3000UC3UAk60M00w6001k60A0020k60v0M1zzz0Tzzzzs0zzzzz0TzjzU3zzU0zzzrz01zzzzs0zwzw000000000000000000000002"
StoryFailsafe:="|<>*96$51.0000000003k0C00001zk3s0070SS0lU01w60zqDszMlk7znzzz7ATsSQDUkNVw1W0k0363b4HWAtss00U03yCDs04U0TlXj0zYTXiCM1U8k60knUS371sD6DzzzzzzzkTVwsy7lw000000004"
IngameQuests:="|<>*100$27.zzszzz07zy00zzU07zw00Hz002Ts00HzU82Dw3UFzUz3DwDsNzUy3Dw3kNzUT1Dw209zU01jw00Bzk01by00Azk01by00Czk03ry0Tyzlzy7zA03zs0TzzVzzw"
MaxUpgradeText:="|<>*153$53.zzzzzzzzzszy7zzzzzlzwDzzzzz1zkzzzzzy3z1zzzzzw3w3s2C7Vs7s7U0SC7kDUC30w8T2C8sT1w1y4MFkn2M7AM1XV6AMQMs6768NUklkQC7kq0l3lsQD1s1W7Xls03VVYPxXM0C7Xcnm6M4MT3TU7sTzzryU"
Results:="|<>*89$53.zzzzzzzzzzzzzzzzzz1zzzzztzw1zzzzznzsXzzzzzbzlY4mE0E8HU804U0UGX0080868Vy00k4EAFXwN1mA0Q04Rn3aw5w49zzzzzzzzzU"

;New UI
Teleports:="|<>*105$46.zy00Mzzzzk01Xzzzz002Dzzzy008zzzsTzzzrzy0zzzyDzsVzxwstz74N1V13wSFU040Dlt608MkzX4E1UX1y0844207w0kEMQEzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs"
Story:="|<>*150$71.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU031s6DDzzzy1041k6QTzzzwznllbANzzzzszbbnCQ3zzzzkDCDaMwDzzzzsCQTA1szzzzzwQwyM3tzzzzyMtsEn7nzzzzw3ns3bDbzzzzwDbsDCTDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
Raids:="|<>*150$44.zzzzzzzzzzzzzzz0zDn0w7k7lwk61wtsTAsbzCS3nD0zn74wnm1w1l7AwsD0M1nCDXn60An2Mwt7nA1UTCNwn1wDzzzzzzzzzzzzzzy"
NewUpgrade:="|<>*47$39.zzzzzzzzzzzzzzzzzzrzzAzzwzztVUF0Tz80003zs00U0TzW4603zznXzzzzywzzzU"
Retry:="|<>*115$29.000000000000000w20024+0047nzk9802EE09l0U2GW194ZY1zzmE0004U000600000000004"
Settings:="|<>*110$17.zzzzDzs7zX7zjTzSzwMzy7zyTzzzzzzk"
UnitManager:="|<>*108$56.zzzzzzzzzzzzzzzzzzyRwjjTzzzzbTvlXzzzztnkQ0zzzzyQ470032AEm5/k1G5+4w12Qw4UEVDWKbzF/6AHzzzzzzzXzzzzzzzzxzy"
PortalSelection:="|<>*108$56.zzzzzzzzzzzzzzzzzzyRwjjTzzzzbTvlXzzzztnkQ0zzzzyQ470032AEm5/k1G5+4w12Qw4UEVDWKbzF/6AHzzzzzzzXzzzzzzzzxzy"
LobbyIcon:="|<>**50$11.TwX9SGwZ1/mLYX+"
AutoOff:="|<>*51$13.zzw1w0Q060301U0k0M0A060301k1w1zzw"
AutoOff2:="|<>*53$13.zzw1w0Q060301U0k0M0A060301U0s0y0zzy"

StartButton:="|<>*121$25.00003s043y0735U6l2zzQW402wgdrtG4ty9WQzzzzzzzzz"
RaidSelectButton:="|<>*120$29.00000S3U01a903a7mzwcTbztsFAMVs0EFbs0UDD0xD6TAP6CzzzzzzzzzzU"
DungeonSelectButton:="|<>*120$28.00000w6024MY0IVyTzO7tzswMaA3l2EbS492QwMqAHzzzzzzzzzs"
UnitManager:="|<>*121$67.zzzzzzzzzzzzzzzzzzzzzzwTjn3UTzzNzwDrtVwzzzjzyC1sEyMUA21XmJw8T9GIf2ZZ+y0DY92JVEslCxHr6lWGgTzzzzzzuzzyjzzzzzzzzzzzzzzzzzzzzzz"
AbilityManager:="|<>*118$65.zzzzzzzzzzz0Tznzv/xzjz3zzbzW7lzTz7zzDz4DXwTyMlWMw0S0UlwY+IZs0w1/9x+493m5t2GLz6AP7z9zlaDzxOzzzzzzzzzxvzzzzzzzzzzzzzzzzzzk"

; === Upgrade Limits === (630, 375, 717, 385)
Upgrade0:="|<>*49$6.zvlZZUkzzU"
Upgrade1:="|<>*47$6.zztltsszzzU"
Upgrade2:="|<>*45$8.zzzCVcHYUM7zzs"
Upgrade3:="|<>*52$8.zyz6lCG1kTy"
Upgrade4:="|<>*54$9.zyAVg9kTXzw"
Upgrade5:="|<>*47$8.zyT3lg/klDy"
Upgrade6:="|<>*47$6.zzzlXVUkzzU"
Upgrade7:="|<>*41$10.zzzwBknmSNtDgzzzy"
Upgrade8:="|<>*69$8.zzz6VgK5mzy"
Upgrade9:="|<>*48$8.zwu6VAH1WTzzU"
Upgrade10:="|<>*43$11.zzzztq1c2MEk3Y7zzzs"
Upgrade11:="|<>*41$11.zzzr1Y2QYt3m7zzzw"
Upgrade12:="|<>*45$13.zzzzznj0n0Hn9s1w0zzzzy"
Upgrade13:="|<>*45$11.zzzztq1cWNYk3U7zzzs"
Upgrade14:="|<>*44$13.zzzyw341/0bU7nXzzzzw"

; === Nuke Wave Configuration ===
Wave15:="|<>*127$34.zzzzzzb1wtkQ87X21UUS8842Dk0Xs8D623s0MS07W1XsUSDWDXss0Fy07U17s0SM8za3zzrzzy"

Wave20 := "|<>*84$16.zzzzzz6DsETY9zYbwGzUXzzzzzy"
Wave50 := "|<>*110$10.zz4M1WG1C5n7zs"
