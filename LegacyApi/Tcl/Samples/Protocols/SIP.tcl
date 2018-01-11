#
# setup path and load IxLoad package
#

source ../setup_simple.tcl

#
# Initialize IxLoad
#

#-----------------------------------------------------------------------
# Connect
#-----------------------------------------------------------------------
# IxLoad connect should always be called, even for local scripts
::IxLoad connect $::IxLoadPrivate::SimpleSettings::remoteServer

# once we've connected, make sure we disconnect, even if there's a problem
if [catch {
# setup logger
set logtag "IxLoad-api"
set logName "new_SIP"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1
# Loads plugins for specific protocols configured in this test
global ixAppPluginManager
$ixAppPluginManager load "SIP"

#################################################
# Build chassis chain
#################################################
set chassisChain [::IxLoad new ixChassisChain]
$chassisChain addChassis $::IxLoadPrivate::SimpleSettings::chassisName
set my_ixViewOptions [::IxLoad new ixViewOptions]
$my_ixViewOptions config \
	-runMode                                 1 \
	-captureRunDuration                      0 \
	-captureRunAfter                         0 \
	-collectScheme                           0 \
	-allocatedBufferMemoryPercentage         30 

set simplesiptest [::IxLoad new ixTest]

set scenarioElementFactory [$simplesiptest getScenarioElementFactory]


$simplesiptest scenarioList.clear

set TrafficFlow1 [::IxLoad new ixTrafficFlow]
$TrafficFlow1 columnList.clear

set Client [::IxLoad new ixTrafficColumn]
$Client elementList.clear

#################################################
# Create ScenarioElement kNetTraffic
#################################################
set client_traffic_clnt_network [$scenarioElementFactory create $::ixScenarioElementType(kNetTraffic)]

#################################################
# Activity my_sip_client of NetTraffic client_traffic@clnt_network
#################################################
set Activity_my_sip_client [$client_traffic_clnt_network activityList.appendItem \
	-protocolAndType                         "SIP Client" ]

#################################################
# Timeline1 for activities my_sip_client
#################################################
set Timeline1 [::IxLoad new ixTimeline]
$Timeline1 config \
	-rampUpValue                             1 \
	-rampUpType                              0 \
	-offlineTime                             0 \
	-rampDownTime                            20 \
	-standbyTime                             30 \
	-rampDownValue                           0 \
	-iterations                              1 \
	-rampUpInterval                          1 \
	-sustainTime                             40 \
	-timelineType                            0 \
	-name                                    "Timeline1" 

$Activity_my_sip_client config \
	-enable                                  true \
	-name                                    "my_sip_client" \
	-userIpMapping                           "1:1" \
	-enableConstraint                        false \
	-userObjectiveValue                      1 \
	-constraintValue                         100 \
	-userObjectiveType                       "useragents" \
	-timeline                                $Timeline1 

$Activity_my_sip_client agent.config \
	-cmdListLoops                            0 

$Activity_my_sip_client agent.pm.generalSettings.config \
	-dhcpServerPort                          5060 \
	-ipv6Form                                0 \
	-bRemoveCredent                          false \
	-bRegBefore                              false \
	-type_of_service_for_rtp                 "Best Effort (0x0)" \
	-_gbDhcpServerPort                       false \
	-nUdpMaxSize                             1024 \
	-nUdpPort                                5060 \
	-szAuthDomain                            "domain" \
	-vlan_priority_sip                       0 \
	-useDhcp                                 false \
	-enableTosSIP                            false \
	-reRegisterSeconds                       3600 \
	-ipPreference                            0 \
	-_gbIpPreference                         false \
	-nPrefQop                                0 \
	-szRegistrar                             "127.0.0.1:5060" \
	-enableVlanPriority_for_sip              false \
	-nTcpPort                                5060 \
	-reRegisterOption                        0 \
	-szTransport                             "UDP" \
	-szAuthPassword                          "password" \
	-type_of_service_for_sip                 "Best Effort (0x0)" \
	-szAuthUsername                          "user" \
	-enableTosRTP                            false \
	-compressZeros                           false \
	-reRegister                              false \
	-reRegisterPercentage                    50 

#---------------------------------------------------------------------------------------------------------
#pm.mediaSettings.config
#
#Configuring codec and codec settings:
#-szCodecName - defines the codec to be used for RTP streams and can have the following values:
#	"G711ALaw" - for G.711 A-law
#	"G711ULaw" - for G.711 mu-law
#	"G729A"  - for G.729A
#	"G729B"  - for G.729B
#	"G726"   - for G.726
#	"G723_1" - for G.723.1
#	"AMR"    - for AMR
#	"iLBC"   - for ILBC
#-szBitRate - defines the bit rate for the codec being used. Depending on the codec the following values are valid:
#	G711Alaw	"64 kbps"
#	G711Ulaw	"64 kbps"
#	G723.1		"5.3 kbps", "6.3 kbps"
#	G726		"40 kbps"
#	G729A		"8 kbps"
#	G729B		"8 kbps"
#	AMR		"4.75 kbps", "5.15 kbps", "5.9 kbps", "6.7 kbps", "7.4 kbps", "7.95 kbps", "10.2 kbps", "12.2 kbps"
#	iLBC		"13.33 kbps", "15.2 kbps"
#-szCodecDetails - defines the codec details and has the following format:
#	BF<val1>PT<val2>
#   - <val1> represents number of codec bytes per frame
#   - <val2> represents the packet time
#  The possible values for <val1> and <val2> depend on codec type and bitrate
#
#Silence generation options:
#-bUseSilence - specifies if silence generation should be used (value 1) or not (value 0)
#-bSilenceMode - specifies the type of silence:
#	0 - Comfort Noise
#	1 - NULL data encoded using the configured codec
#---------------------------------------------------------------------------------------------------------

$Activity_my_sip_client agent.pm.mediaSettings.config \
	-nPcInterval                             500 \
	-nJitterBuffer                           1 \
	-nDtmfInterdigits                        40 \
	-nCompMaxDropped                         7 \
	-nPeerDtmfDuration                       100 \
	-nJitterMs                               20 \
	-bSilenceMode                            1 \
	-nAudioPoolTime                          1268046858 \
	-szBitRate                               "64 kbps" \
	-nDtmfDuration                           100 \
	-szPeerCodecName                         "G711ALaw" \
	-szSilenceFile                           "C:\\Program Files\\Ixia\\IxLoad\\5.0.117.11-EB\\Client\\Plugins\\agent\\SIP_Client\\Pool\\Audio\\_G711ALaw_20ms_silence.raw" \
	-bytesPerFrameBuffer                     "" \
	-groupBox_MOS1                           false \
	-szPeerCodecDetails                      "BF160PT20" \
	-bMosOnMax                               0 \
	-groupBox_JB1                            false \
	-nMosInterval                            3 \
	-nCompJitterBuffer                       50 \
	-bUseJitter                              false \
	-szCodecName                             "G711ALaw" \
	-szPeerDtmfSeq                           "12345" \
	-bLimitDtmf                              true \
	-bUseMOS                                 false \
	-bJitMs                                  0 \
	-szCodecDescr                            "" \
	-bCompMs                                 0 \
	-nDtmfStreams                            10 \
	-packetTimeBuffer                        "" \
	-szPowerLevel                            "PL_20" \
	-szDtmfSeq                               "12345" \
	-nCompJitterMs                           1000 \
	-nPeerDtmfInterdigits                    40 \
	-bRtpStartCollector                      false \
	-nMosMaxStreams                          1 \
	-szCodecDetails                          "BF160PT20" \
	-nSessionType                            49 \
	-bUseSilence                             true \
	-bModifyPowerLevel                       false \
	-bUseCompensation                        false 

$Activity_my_sip_client agent.pm.contentOfMessages.config \
	-bFolding                                false \
	-bBestPerformance                        1 \
	-szRoute                                 "Route: &lt;sip:p1.example.com;lr&gt;,&lt;sip:p2.domain.com;lr&gt;" \
	-bOptional                               false \
	-szCONTACT                               "sip:id@IP" \
	-bAdvisable                              false \
	-bCompact                                false \
	-bRoute                                  false \
	-szFROM                                  "sip:id@IP" \
	-szTO                                    "sip:id@IP" \
	-szREQUESTURI                            "sip:id@IP" \
	-bScattered                              false 

$Activity_my_sip_client agent.pm.contentOfMessages.rulesTable.clear

$Activity_my_sip_client agent.pm.stateMachine.config \
	-bNextOnFail                             true \
	-nTimersT4                               5000 \
	-nReRegDuration                          0 \
	-nTimersT1                               500 \
	-nTimersT2                               4000 \
	-bUseTimer                               false \
	-nTimeout                                30000 \
	-nTimersTD                               32000 \
	-nTimersTC                               180000 \
	-bRecv5xx                                false 

$Activity_my_sip_client agent.pm.videoSettings.config \
	-videoBitrate                            128.0 \
	-videoBitrateLimit                       103500000 

$Activity_my_sip_client agent.pm.config \
	-szPluginVersion                         "3.40" \
	-objectiveValue                          1 

$Activity_my_sip_client agent.pm.scenarios.clear

$Activity_my_sip_client agent.pm.scenarios.appendItem \
	-lateSDPNegotiation                      false \
	-bNextCommandIsDetect                    false \
	-symDestination                          "198.18.0.101:5060" \
	-isLastCmd                               false \
	-useDhcpForOriginate                     false \
	-commandType                             "ORIGINATECALL" \
	-hasVideo                                false \
	-cmdName                                 "Originate Call 1" \
	-dhcpServerPortForOriginate              5060 \
	-_gbDhcpServerPortForOriginate           false 

$Activity_my_sip_client agent.pm.scenarios.appendItem \
	-nRepeatCount                            1 \
	-nWavDuration                            0 \
	-nTimeUnit                               0 \
	-nPlayMode                               1 \
	-nSessionType                            0 \
	-bNextCommandIsDetect                    false \
	-isLastCmd                               false \
	-cmdName                                 "Voice Session 2" \
	-commandType                             "VOICESESSION" \
	-szAudioFile                             "speech.wav" \
	-szDtmfSeq                               "12345" \
	-szTotalTime                             "1 s" \
	-nTotalTime                              1000 \
	-nPlayTime                               1 
#---------------------------------------------------------------------------------------------------------
#The GENERATEMF comand has the following possible paramters:
#-szMfSeq - the sequence of MF digits to be generated
#-nMfDuration - the duration of a MF digit; value range [10 990]
#-nInterMfInterval - the silence between the MF digits; value range [10 9990]
#-nMfAmplitude - the amplitude of the signal generated by the sending sequence; value range [-30 -10]
#-nPlayMode - the pley mode; possible values: 0 - generate fo a specified period of time
#					      1 - repeat for a specified number of times
#-nRepeatCount - number of times to repeat the generation of the sequence
#-nPlayTime - the time units to plays the specified sequence
#-nTimeUnit - time unit type; possible values: 0 - seconds
#					       1 - minutes
#					       2 - hours
#					       3 - days
#---------------------------------------------------------------------------------------------------------
$Activity_my_sip_client agent.pm.scenarios.appendItem \
	-nRepeatCount                            1 \
	-szMfSeq                                 "12345" \
	-nTimeUnit                               0 \
	-nPlayMode                               1 \
	-szCodecDetails                          "BF160PT20" \
	-bNextCommandIsDetect                    false \
	-nMfDuration                             200 \
	-isLastCmd                               false \
	-nInterMfInterval                        40 \
	-szCodecName                             "G711ALaw" \
	-commandType                             "GENERATEMF" \
	-cmdName                                 "Generate MF 3" \
	-nMfAmplitude                            -10 \
	-szTotalTime                             "30 s" \
	-nTotalTime                              30000 \
	-nPlayTime                               30 
#---------------------------------------------------------------------------------------------------------
#The GENERATETONE comand has the following possible paramters:
#-nToneName - the id for the tone
#		possible values: 0 - "600-10"
#     				 1 - "1400-10"
#				 2 - "2500-10"
#				 3 - "550-20"
#				 4 - "1350-20"
#				 5 - "2450-20"
#				 6 - "650-30"
#				 7 - "2550-30"
#				 8 - "1450-30"
#				 9 - "3400-10"
#				 10 - "3400-30"
#				 11 - "2100-10"
#				 12 - "2150-30"
#				 13 - "400-10"
#				 14 - "450-30"
#				 15 - "Confirmation Tone"
#				 16 - "Call Waiting Tone"
#				 17 - "TN_1"
#				 -1 -"Custom Tone"
#
#-nPlayMode - the pley mode; possible values: 0 - generate fo a specified period of time
#					      1 - repeat for a specified number of times
#-nRepeatCount - number of times to repeat the generation of the sequence
#-nPlayTime - the time units to plays the specified sequence
#-nTimeUnit - time unit type; possible values: 0 - seconds
#					       1 - minutes
#					       2 - hours
#					       3 - days
#-nToneDuration - the duration of a tone with only one frequency
#-nFrequency1 - first frequency
#-nFrequency2 - second frequency
#-nAmplitude1 - first amplitude
#-nAmplitude2 - second amplitude
#-nOnTime - nOnTime must be equal to nToneDuration
#-nOffTime - the duration of silence 
#-nRepetitionCount - the number of repetition for the specified tone
#-nToneType - the tone type; possible values: 	0 -"Single Tone"
#						1 - "Dual Tone"
#						2 - "Single Tone Cadence"
#						3 - "Dual Tone Cadence"
#---------------------------------------------------------------------------------------------------------
$Activity_my_sip_client agent.pm.scenarios.appendItem \
	-bNextCommandIsDetect                    false \
	-isLastCmd                               false \
	-nOffTime                                0 \
	-cmdName                                 "Generate Tone 4" \
	-nToneType                               0 \
	-nToneName                               0 \
	-nOnTime                                 100 \
	-szCodecName                             "G711ALaw" \
	-nRepeatCount                            1 \
	-nTimeUnit                               0 \
	-nPlayMode                               1 \
	-nAmplitude1                             -10 \
	-nAmplitude2                             0 \
	-commandType                             "GENERATETONE" \
	-nToneDuration                           100 \
	-szTotalTime                             "30 s" \
	-nPlayTime                               30 \
	-szCodecDetails                          "BF160PT20" \
	-nFrequency2                             0 \
	-nFrequency1                             615 \
	-nRepetitionCount                        1 \
	-nTotalTime                              30000 

$Activity_my_sip_client agent.pm.scenarios.appendItem \
	-commandType                             "ENDCALL" \
	-isLastCmd                               true \
	-cmdName                                 "End Call 5" \
	-szDummy03                               "" 

$Activity_my_sip_client agent.pm.predefined_tos_for_rtp.clear

$Activity_my_sip_client agent.pm.predefined_tos_for_sip.clear

#################################################
# Network clnt_network of NetTraffic client_traffic@clnt_network
#################################################
set clnt_network [$client_traffic_clnt_network cget -network]
$clnt_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)
	
$clnt_network globalPlugins.clear


set Filter_1 [::IxLoad new ixNetFilterPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $Filter_1

$Filter_1 config \
	-all                                     false \
	-pppoecontrol                            false \
	-isis                                    false \
	-auto                                    true \
	-udp                                     "" \
	-tcp                                     "" \
	-mac                                     "" \
	-pppoenetwork                            false \
	-ip                                      "" \
	-icmp                                    "" 

set GratARP_1 [::IxLoad new ixNetGratArpPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $GratARP_1

$GratARP_1 config \
	-forwardGratArp                          false \
	-enabled                                 true 

set TCP_1 [::IxLoad new ixNetTCPPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $TCP_1

$TCP_1 config \
	-tcp_bic                                 0 \
	-tcp_tw_recycle                          true \
	-tcp_retries2                            5 \
	-disable_min_max_buffer_size             true \
	-tcp_retries1                            3 \
	-tcp_keepalive_time                      7200 \
	-tcp_rfc1337                             false \
	-tcp_ipfrag_time                         30 \
	-tcp_rto_max                             60000 \
	-tcp_window_scaling                      false \
	-udp_port_randomization                  false \
	-tcp_vegas_alpha                         2 \
	-tcp_ecn                                 false \
	-tcp_westwood                            0 \
	-tcp_rto_min                             1000 \
	-tcp_reordering                          3 \
	-tcp_vegas_cong_avoid                    0 \
	-tcp_keepalive_intvl                     75 \
	-tcp_rmem_max                            262144 \
	-tcp_orphan_retries                      0 \
	-tcp_max_tw_buckets                      180000 \
	-tcp_wmem_default                        4096 \
	-tcp_low_latency                         0 \
	-tcp_rmem_min                            4096 \
	-tcp_adv_win_scale                       2 \
	-tcp_wmem_min                            4096 \
	-tcp_port_min                            1024 \
	-tcp_stdurg                              false \
	-tcp_port_max                            65535 \
	-tcp_fin_timeout                         60 \
	-tcp_no_metrics_save                     false \
	-tcp_dsack                               true \
	-tcp_abort_on_overflow                   false \
	-tcp_frto                                0 \
	-tcp_app_win                             31 \
	-tcp_vegas_beta                          6 \
	-llm_hdr_gap                             8 \
	-tcp_max_orphans                         8192 \
	-tcp_mem_pressure                        32768 \
	-tcp_syn_retries                         5 \
	-tcp_moderate_rcvbuf                     0 \
	-tcp_max_syn_backlog                     1024 \
	-tcp_mem_low                             24576 \
	-tcp_tw_rfc1323_strict                   false \
	-tcp_fack                                true \
	-tcp_retrans_collapse                    true \
	-llm_hdr_gap_ns                          10 \
	-tcp_rmem_default                        4096 \
	-tcp_keepalive_probes                    9 \
	-tcp_mem_high                            49152 \
	-tcp_tw_reuse                            false \
	-tcp_wmem_max                            262144 \
	-tcp_vegas_gamma                         2 \
	-tcp_synack_retries                      5 \
	-tcp_timestamps                          true \
	-ip_no_pmtu_disc                         true \
	-tcp_sack                                true \
	-tcp_bic_fast_convergence                1 \
	-tcp_bic_low_window                      14 

set DNS_1 [::IxLoad new ixNetDnsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $DNS_1

$DNS_1 hostList.clear


$DNS_1 searchList.clear


$DNS_1 nameServerList.clear


$DNS_1 config \
	-domain                                  "" \
	-timeout                                 30000 

set Settings_1 [::IxLoad new ixNetIxLoadSettingsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $Settings_1

$Settings_1 config \
	-teardownInterfaceWithUser               false \
	-interfaceBehavior                       0 

$clnt_network config \
	-comment                                 "" \
	-name                                    "clnt_network" \
	-macMappingMode                          0 \
	-linkLayerOptions                        0 

set Ethernet_1 [$clnt_network getL1Plugin]

set my_ixNetEthernetELMPlugin [::IxLoad new ixNetEthernetELMPlugin]
$my_ixNetEthernetELMPlugin config \
	-negotiationType                         "master" \
	-negotiateMasterSlave                    true 

set my_ixNetDualPhyPlugin [::IxLoad new ixNetDualPhyPlugin]
$my_ixNetDualPhyPlugin config \
	-medium                                  "copper" 

$Ethernet_1 childrenList.clear


set MAC_VLAN_2 [::IxLoad new ixNetL2EthernetPlugin]
# ixNet objects needs to be added in the list before they are configured!
$Ethernet_1 childrenList.appendItem -object $MAC_VLAN_2

$MAC_VLAN_2 childrenList.clear


set IP_2 [::IxLoad new ixNetIpV4V6Plugin]
# ixNet objects needs to be added in the list before they are configured!
$MAC_VLAN_2 childrenList.appendItem -object $IP_2

$IP_2 childrenList.clear


$IP_2 extensionList.clear


$MAC_VLAN_2 extensionList.clear


$Ethernet_1 extensionList.clear


$Ethernet_1 config \
	-advertise10Full                         true \
	-directedAddress                         "01:80:C2:00:00:01" \
	-autoNegotiate                           true \
	-advertise100Half                        true \
	-advertise10Half                         true \
	-enableFlowControl                       false \
	-speed                                   "k100FD" \
	-advertise1000Full                       true \
	-advertise100Full                        true \
	-cardElm                                 $my_ixNetEthernetELMPlugin \
	-cardDualPhy                             $my_ixNetDualPhyPlugin 

#################################################
# Setting the ranges starting with the plugin on top of the stack
#################################################
$IP_2 rangeList.clear

set IP_R2 [::IxLoad new ixNetIpV4V6Range]
# ixNet objects needs to be added in the list before they are configured.
$IP_2 rangeList.appendItem -object $IP_R2

$IP_R2 config \
	-count                                   1 \
	-enableGatewayArp                        false \
	-generateStatistics                      false \
	-autoCountEnabled                        false \
	-enabled                                 true \
	-autoMacGeneration                       false \
	-publishStats                            false \
	-incrementBy                             "0.0.0.1" \
	-prefix                                  16 \
	-gatewayIncrement                        "0.0.0.0" \
	-gatewayIncrementMode                    "perSubnet" \
	-mss                                     100 \
	-gatewayAddress                          "0.0.0.0" \
	-ipAddress                               "198.18.0.1" \
	-ipType                                  "IPv4" 

set MAC_R2 [$IP_R2 getLowerRelatedRange "MacRange"]

$MAC_R2 config \
	-count                                   1 \
	-mac                                     "00:C6:12:02:01:00" \
	-mtu                                     1500 \
	-enabled                                 true \
	-incrementBy                             "00:00:00:00:00:01" 

set VLAN_R2 [$IP_R2 getLowerRelatedRange "VlanIdRange"]

$VLAN_R2 config \
	-incrementStep                           1 \
	-innerIncrement                          1 \
	-firstId                                 1 \
	-uniqueCount                             4094 \
	-idIncrMode                              1 \
	-enabled                                 false \
	-innerFirstId                            1 \
	-innerIncrementStep                      1 \
	-priority                                0 \
	-increment                               1 \
	-innerUniqueCount                        4094 \
	-innerEnable                             false \
	-innerPriority                           0 

#################################################
# Creating the IP Distribution Groups
#################################################
$IP_2 rangeGroups.clear


set DistGroup1 [::IxLoad new ixNetRangeGroup]
# ixNet objects needs to be added in the list before they are configured!
$IP_2 rangeGroups.appendItem -object $DistGroup1

$DistGroup1 rangeList.clear

$DistGroup1 rangeList.appendItem -object $IP_R2

$DistGroup1 config \
	-distribType                             0 \
	-name                                    "DistGroup1" 

$client_traffic_clnt_network config \
	-enable                                  true \
	-network                                 $clnt_network 

$client_traffic_clnt_network traffic.config \
	-name                                    "client_traffic" 

$client_traffic_clnt_network setPortOperationModeAllowed $::ixPort(kOperationModeThroughputAcceleration) false
$client_traffic_clnt_network setTcpAccelerationAllowed $::ixAgent(kTcpAcceleration) true
$Client elementList.appendItem -object $client_traffic_clnt_network

$Client config \
	-name                                    "Client" 

$TrafficFlow1 columnList.appendItem -object $Client

set Server [::IxLoad new ixTrafficColumn]
$Server elementList.clear

#################################################
# Create ScenarioElement kNetTraffic
#################################################
set server_traffic_svr_network [$scenarioElementFactory create $::ixScenarioElementType(kNetTraffic)]

#################################################
# Activity my_sip_server of NetTraffic server_traffic@svr_network
#################################################
set Activity_my_sip_server [$server_traffic_svr_network activityList.appendItem \
	-protocolAndType                         "SIP Server" ]

set _Match_Longest_ [::IxLoad new ixMatchLongestTimeline]

$Activity_my_sip_server config \
	-enable                                  true \
	-name                                    "my_sip_server" \
	-timeline                                $_Match_Longest_ 

$Activity_my_sip_server agent.config \
	-cmdListLoops                            0 

$Activity_my_sip_server agent.pm.generalSettings.config \
	-dhcpServerPort                          5060 \
	-ipv6Form                                0 \
	-bRemoveCredent                          false \
	-bRegBefore                              false \
	-type_of_service_for_rtp                 "Best Effort (0x0)" \
	-_gbDhcpServerPort                       false \
	-nUdpMaxSize                             1024 \
	-regInterval                             0 \
	-szAuthDomain                            "domain" \
	-vlan_priority_sip                       0 \
	-useDhcp                                 false \
	-enableTosSIP                            false \
	-nUdpPort                                5060 \
	-reRegisterSeconds                       3600 \
	-ipPreference                            0 \
	-_gbIpPreference                         false \
	-nPrefQop                                0 \
	-szRegistrar                             "127.0.0.1:5060" \
	-enableVlanPriority_for_sip              false \
	-nTcpPort                                5060 \
	-reRegisterOption                        0 \
	-szTransport                             "UDP" \
	-szAuthPassword                          "password" \
	-type_of_service_for_sip                 "Best Effort (0x0)" \
	-szAuthUsername                          "user" \
	-enableTosRTP                            false \
	-compressZeros                           false \
	-reRegister                              false \
	-reRegisterPercentage                    50 

$Activity_my_sip_server agent.pm.mediaSettings.config \
	-nPcInterval                             500 \
	-nJitterBuffer                           1 \
	-nDtmfInterdigits                        40 \
	-nCompMaxDropped                         7 \
	-nPeerDtmfDuration                       100 \
	-nJitterMs                               20 \
	-bSilenceMode                            1 \
	-nAudioPoolTime                          1268046860 \
	-szBitRate                               "64 kbps" \
	-nDtmfDuration                           100 \
	-szPeerCodecName                         "G711ALaw" \
	-szSilenceFile                           "" \
	-bytesPerFrameBuffer                     "" \
	-groupBox_MOS1                           false \
	-szPeerCodecDetails                      "BF160PT20" \
	-bMosOnMax                               0 \
	-groupBox_JB1                            false \
	-nMosInterval                            3 \
	-nCompJitterBuffer                       50 \
	-bUseJitter                              false \
	-szCodecName                             "G711ALaw" \
	-szPeerDtmfSeq                           "12345" \
	-bLimitDtmf                              true \
	-bUseMOS                                 false \
	-bJitMs                                  0 \
	-szCodecDescr                            "" \
	-bCompMs                                 0 \
	-nDtmfStreams                            10 \
	-packetTimeBuffer                        "" \
	-szPowerLevel                            "PL_20" \
	-szDtmfSeq                               "12345" \
	-nCompJitterMs                           1000 \
	-nPeerDtmfInterdigits                    40 \
	-bRtpStartCollector                      false \
	-nMosMaxStreams                          1 \
	-szCodecDetails                          "BF160PT20" \
	-nSessionType                            16384 \
	-bUseSilence                             false \
	-bModifyPowerLevel                       false \
	-bUseCompensation                        false 

$Activity_my_sip_server agent.pm.contentOfMessages.config \
	-bFolding                                false \
	-bBestPerformance                        1 \
	-szTO                                    "sip:id@IP" \
	-bOptional                               false \
	-szCONTACT                               "sip:id@IP" \
	-bAdvisable                              false \
	-bCompact                                false \
	-szFROM                                  "sip:id@IP" \
	-szREQUESTURI                            "sip:IP" \
	-bScattered                              false 

$Activity_my_sip_server agent.pm.contentOfMessages.rulesTable.clear

$Activity_my_sip_server agent.pm.stateMachine.config \
	-nActiveTimeout                          0 \
	-bUasStateless                           false \
	-nActiveTimeoutValue                     0 \
	-nTimersT4                               5000 \
	-nTimersT1                               500 \
	-nTimersT2                               4000 \
	-nTimersTD                               32000 \
	-nActiveTimeoutTU                        0 \
	-nTimersTC                               180000 

$Activity_my_sip_server agent.pm.videoSettings.config \
	-videoBitrate                            128.0 \
	-videoBitrateLimit                       103500000 

$Activity_my_sip_server agent.pm.config \
	-szPluginVersion                         "3.40" \
	-objectiveValue                          1 

$Activity_my_sip_server agent.pm.scenarios.clear

$Activity_my_sip_server agent.pm.scenarios.appendItem \
	-commandType                             "RECEIVEUSING180" \
	-bNextCommandIsDetect                    false \
	-szDummy10                               "" \
	-cmdName                                 "Receive using 180 1" \
	-isLastCmd                               true 

$Activity_my_sip_server agent.pm.predefined_tos_for_rtp.clear

$Activity_my_sip_server agent.pm.predefined_tos_for_sip.clear

#################################################
# Network svr_network of NetTraffic server_traffic@svr_network
#################################################
set svr_network [$server_traffic_svr_network cget -network]
$svr_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID) \
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)
	
$svr_network globalPlugins.clear


set Filter_2 [::IxLoad new ixNetFilterPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $Filter_2

$Filter_2 config \
	-all                                     false \
	-pppoecontrol                            false \
	-isis                                    false \
	-auto                                    true \
	-udp                                     "" \
	-tcp                                     "" \
	-mac                                     "" \
	-pppoenetwork                            false \
	-ip                                      "" \
	-icmp                                    "" 

set GratARP_2 [::IxLoad new ixNetGratArpPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $GratARP_2

$GratARP_2 config \
	-forwardGratArp                          false \
	-enabled                                 true 

set TCP_2 [::IxLoad new ixNetTCPPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $TCP_2

$TCP_2 config \
	-tcp_bic                                 0 \
	-tcp_tw_recycle                          true \
	-tcp_retries2                            5 \
	-disable_min_max_buffer_size             true \
	-tcp_retries1                            3 \
	-tcp_keepalive_time                      7200 \
	-tcp_rfc1337                             false \
	-tcp_ipfrag_time                         30 \
	-tcp_rto_max                             60000 \
	-tcp_window_scaling                      false \
	-udp_port_randomization                  false \
	-tcp_vegas_alpha                         2 \
	-tcp_ecn                                 false \
	-tcp_westwood                            0 \
	-tcp_rto_min                             1000 \
	-tcp_reordering                          3 \
	-tcp_vegas_cong_avoid                    0 \
	-tcp_keepalive_intvl                     75 \
	-tcp_rmem_max                            262144 \
	-tcp_orphan_retries                      0 \
	-tcp_max_tw_buckets                      180000 \
	-tcp_wmem_default                        4096 \
	-tcp_low_latency                         0 \
	-tcp_rmem_min                            4096 \
	-tcp_adv_win_scale                       2 \
	-tcp_wmem_min                            4096 \
	-tcp_port_min                            1024 \
	-tcp_stdurg                              false \
	-tcp_port_max                            65535 \
	-tcp_fin_timeout                         60 \
	-tcp_no_metrics_save                     false \
	-tcp_dsack                               true \
	-tcp_abort_on_overflow                   false \
	-tcp_frto                                0 \
	-tcp_app_win                             31 \
	-tcp_vegas_beta                          6 \
	-llm_hdr_gap                             8 \
	-tcp_max_orphans                         8192 \
	-tcp_mem_pressure                        32768 \
	-tcp_syn_retries                         5 \
	-tcp_moderate_rcvbuf                     0 \
	-tcp_max_syn_backlog                     1024 \
	-tcp_mem_low                             24576 \
	-tcp_tw_rfc1323_strict                   false \
	-tcp_fack                                true \
	-tcp_retrans_collapse                    true \
	-llm_hdr_gap_ns                          10 \
	-tcp_rmem_default                        4096 \
	-tcp_keepalive_probes                    9 \
	-tcp_mem_high                            49152 \
	-tcp_tw_reuse                            false \
	-tcp_wmem_max                            262144 \
	-tcp_vegas_gamma                         2 \
	-tcp_synack_retries                      5 \
	-tcp_timestamps                          true \
	-ip_no_pmtu_disc                         true \
	-tcp_sack                                true \
	-tcp_bic_fast_convergence                1 \
	-tcp_bic_low_window                      14 

set DNS_2 [::IxLoad new ixNetDnsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $DNS_2

$DNS_2 hostList.clear


$DNS_2 searchList.clear


$DNS_2 nameServerList.clear


$DNS_2 config \
	-domain                                  "" \
	-timeout                                 30000 

set Settings_2 [::IxLoad new ixNetIxLoadSettingsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $Settings_2

$Settings_2 config \
	-teardownInterfaceWithUser               false \
	-interfaceBehavior                       0 

$svr_network config \
	-comment                                 "" \
	-name                                    "svr_network" \
	-macMappingMode                          0 \
	-linkLayerOptions                        0 

set Ethernet_2 [$svr_network getL1Plugin]

set my_ixNetEthernetELMPlugin1 [::IxLoad new ixNetEthernetELMPlugin]
$my_ixNetEthernetELMPlugin1 config \
	-negotiationType                         "master" \
	-negotiateMasterSlave                    true 

set my_ixNetDualPhyPlugin1 [::IxLoad new ixNetDualPhyPlugin]
$my_ixNetDualPhyPlugin1 config \
	-medium                                  "copper" 

$Ethernet_2 childrenList.clear


set MAC_VLAN_1 [::IxLoad new ixNetL2EthernetPlugin]
# ixNet objects needs to be added in the list before they are configured!
$Ethernet_2 childrenList.appendItem -object $MAC_VLAN_1

$MAC_VLAN_1 childrenList.clear


set IP_1 [::IxLoad new ixNetIpV4V6Plugin]
# ixNet objects needs to be added in the list before they are configured!
$MAC_VLAN_1 childrenList.appendItem -object $IP_1

$IP_1 childrenList.clear


$IP_1 extensionList.clear


$MAC_VLAN_1 extensionList.clear


$Ethernet_2 extensionList.clear


$Ethernet_2 config \
	-advertise10Full                         true \
	-directedAddress                         "01:80:C2:00:00:01" \
	-autoNegotiate                           true \
	-advertise100Half                        true \
	-advertise10Half                         true \
	-enableFlowControl                       false \
	-speed                                   "k100FD" \
	-advertise1000Full                       true \
	-advertise100Full                        true \
	-cardElm                                 $my_ixNetEthernetELMPlugin1 \
	-cardDualPhy                             $my_ixNetDualPhyPlugin1 

#################################################
# Setting the ranges starting with the plugin on top of the stack
#################################################
$IP_1 rangeList.clear

set IP_R1 [::IxLoad new ixNetIpV4V6Range]
# ixNet objects needs to be added in the list before they are configured.
$IP_1 rangeList.appendItem -object $IP_R1

$IP_R1 config \
	-count                                   1 \
	-enableGatewayArp                        false \
	-generateStatistics                      false \
	-autoCountEnabled                        false \
	-enabled                                 true \
	-autoMacGeneration                       false \
	-publishStats                            false \
	-incrementBy                             "0.0.0.1" \
	-prefix                                  16 \
	-gatewayIncrement                        "0.0.0.0" \
	-gatewayIncrementMode                    "perSubnet" \
	-mss                                     1460 \
	-gatewayAddress                          "0.0.0.0" \
	-ipAddress                               "198.18.0.101" \
	-ipType                                  "IPv4" 

set MAC_R1 [$IP_R1 getLowerRelatedRange "MacRange"]

$MAC_R1 config \
	-count                                   1 \
	-mac                                     "00:C6:12:02:02:00" \
	-mtu                                     1500 \
	-enabled                                 true \
	-incrementBy                             "00:00:00:00:00:01" 

set VLAN_R1 [$IP_R1 getLowerRelatedRange "VlanIdRange"]

$VLAN_R1 config \
	-incrementStep                           1 \
	-innerIncrement                          1 \
	-firstId                                 1 \
	-uniqueCount                             4094 \
	-idIncrMode                              1 \
	-enabled                                 false \
	-innerFirstId                            1 \
	-innerIncrementStep                      1 \
	-priority                                0 \
	-increment                               1 \
	-innerUniqueCount                        4094 \
	-innerEnable                             false \
	-innerPriority                           0 

#################################################
# Creating the IP Distribution Groups
#################################################
$IP_1 rangeGroups.clear


set DistGroup2 [::IxLoad new ixNetRangeGroup]
# ixNet objects needs to be added in the list before they are configured!
$IP_1 rangeGroups.appendItem -object $DistGroup2

$DistGroup2 rangeList.clear

$DistGroup2 rangeList.appendItem -object $IP_R1

$DistGroup2 config \
	-distribType                             0 \
	-name                                    "DistGroup1" 

$server_traffic_svr_network config \
	-enable                                  true \
	-network                                 $svr_network 

$server_traffic_svr_network traffic.config \
	-name                                    "server_traffic" 

$server_traffic_svr_network setPortOperationModeAllowed $::ixPort(kOperationModeThroughputAcceleration) false
$server_traffic_svr_network setTcpAccelerationAllowed $::ixAgent(kTcpAcceleration) true
$Server elementList.appendItem -object $server_traffic_svr_network

$Server config \
	-name                                    "Server" 

$TrafficFlow1 columnList.appendItem -object $Server

$TrafficFlow1 links.clear

$TrafficFlow1 config \
	-name                                    "TrafficFlow1" 

$simplesiptest scenarioList.appendItem -object $TrafficFlow1

$simplesiptest config \
	-comment                                 "" \
	-csvInterval                             4 \
	-networkFailureThreshold                 0 \
	-name                                    "simplesiptest" \
	-statsRequired                           true \
	-enableResetPorts                        true \
	-statViewThroughputUnits                 "Kbps" \
	-enableForceOwnership                    false \
	-enableReleaseConfigAfterRun             false \
	-currentUniqueIDForAgent                 0 \
	-enableNetworkDiagnostics                false \
	-enableFrameSizeDistributionStats        false \
	-allowMultiple1GAggregatedPorts          false \
	-enableTcpAdvancedStats                  false \
	-captureViewOptions                      $my_ixViewOptions 

#################################################
# Session Specific Settings
#################################################
set my_ixNetMacSessionData [$simplesiptest getSessionSpecificData "L2EthernetPlugin"]
$my_ixNetMacSessionData config \
	-duplicateCheckingScope                  2 

set my_ixNetIpSessionData [$simplesiptest getSessionSpecificData "IpV4V6Plugin"]
$my_ixNetIpSessionData config \
	-enableGatewayArp                        false \
	-maxOutstandingGatewayArpRequests        300 \
	-gatewayArpRequestRate                   300 \
	-duplicateCheckingScope                  2 

#################################################
# Create the test controller to run the test
#################################################
set testController [::IxLoad new ixTestController -outputDir True]

$testController setResultDir "RESULTS/new_SIP"

$testController run $simplesiptest

vwait ::ixTestControllerMonitor
puts $::ixTestControllerMonitor

#################################################
# Cleanup
#################################################
# Release config is only strictly necessary if enableReleaseConfigAfterRun is 0.
$testController releaseConfigWaitFinish

::IxLoad delete $chassisChain
::IxLoad delete $simplesiptest
::IxLoad delete $my_ixViewOptions
::IxLoad delete $TrafficFlow1
::IxLoad delete $Client
::IxLoad delete $client_traffic_clnt_network
::IxLoad delete $Activity_my_sip_client
::IxLoad delete $Timeline1
::IxLoad delete $clnt_network
::IxLoad delete $Filter_1
::IxLoad delete $GratARP_1
::IxLoad delete $TCP_1
::IxLoad delete $DNS_1
::IxLoad delete $Settings_1
::IxLoad delete $Ethernet_1
::IxLoad delete $my_ixNetEthernetELMPlugin
::IxLoad delete $my_ixNetDualPhyPlugin
::IxLoad delete $MAC_VLAN_2
::IxLoad delete $IP_2
::IxLoad delete $IP_R2
::IxLoad delete $MAC_R2
::IxLoad delete $VLAN_R2
::IxLoad delete $DistGroup1
::IxLoad delete $Server
::IxLoad delete $server_traffic_svr_network
::IxLoad delete $Activity_my_sip_server
::IxLoad delete $_Match_Longest_
::IxLoad delete $svr_network
::IxLoad delete $Filter_2
::IxLoad delete $GratARP_2
::IxLoad delete $TCP_2
::IxLoad delete $DNS_2
::IxLoad delete $Settings_2
::IxLoad delete $Ethernet_2
::IxLoad delete $my_ixNetEthernetELMPlugin1
::IxLoad delete $my_ixNetDualPhyPlugin1
::IxLoad delete $MAC_VLAN_1
::IxLoad delete $IP_1
::IxLoad delete $IP_R1
::IxLoad delete $MAC_R1
::IxLoad delete $VLAN_R1
::IxLoad delete $DistGroup2
::IxLoad delete $my_ixNetMacSessionData
::IxLoad delete $my_ixNetIpSessionData
::IxLoad delete $testController

#################################################
# Disconnect / Release application lock
#################################################
}] {
	puts $errorInfo
}

::IxLoad disconnect
