NetConfig = {}
-- 新的外网 用这个端口号吧 12001
NetConfig.PUBLIC_SPECIAL_SERVER_IP = "192.168.128.129"
NetConfig.PUBLIC_SPECIAL_SERVER_PORT = 10000

NetConfig.PRIVATE_GAME_SERVER_IP = "192.168.128.129"
NetConfig.PRIVATE_GAME_SERVER_PORT = 9000

NetConfig.PUBLIC_GAME_SERVER_IP = "192.168.128.129"
NetConfig.PUBLIC_GAME_SERVER_PORT = 5000

NetConfig.PrivateAuthServerUrl = "192.168.128.129"
NetConfig.PrivateAuthServerUrlPort = 5556

NetConfig.PrivateGameServerUrl = "192.168.128.129"
NetConfig.PrivateGameServerUrlPort = 14288

NetConfig.PrivateGameDomain = "http://192.168.128.129:33061"

NetConfig.PriorityMessages = {
	{id1=5, id2=23}
}

NetConfig.AnnounceAddress = "192.168.128.129/ro"

--sdk login
NetConfig.AccessTokenAuthHost = {CN = {"192.168.128.129","192.168.128.129"},EN = {"192.168.128.129"}}
NetConfig.NewAccessTokenAuthHost = {"192.168.128.129","192.168.128.129","192.168.128.129"}


------------!!!!!!!!!!!!!!!!-------------------
NetConfig.GateHost = {CN = {"192.168.128.129","192.168.128.129"},EN = {"192.168.128.129"}}
NetConfig.NewGateHost = {"192.168.128.129","192.168.128.129","192.168.128.129"}
NetConfig.NewGateHost_NOTEST = {"192.168.128.129","192.168.128.129","192.168.128.129"}

--高防域名
NetConfig.NewGateHostGf =  NetConfig.NewGateHost[1]
--海外域名
NetConfig.NewGateHostFg =  NetConfig.NewGateHost[3]

------------!!!!!!!!!!!!!!!!-------------------

NetConfig.AccessTokenRealNameCentifyUrl_Xd = "/authorize?access_token="
NetConfig.AccessTokenAuthUrl_Xd = "/login?access_token="
-- NetConfig.AccessTokenAuthUrl_AynSdk = ":5556/anylogin?access_token="
NetConfig.ActivateUrl_Xd = "/activate?access_token="
NetConfig.ActivateUrl_AnySdk = "/anyactivate?"
NetConfig.SyncDidUrl = "http://192.168.128.129/v1/user/set_ro_did?did=%s&access_token=%s"

--game server
NetConfig.AliyunSecurityIPSdkAppkey = ""
NetConfig.AliyunSecurityIPSdkServerGroup = {CN = {{"192.168.128.129","192.168.128.129"},{"192.168.128.129","192.168.128.129"},{"192.168.128.129","192.168.128.129"},{"192.168.128.129","192.168.128.129"}},EN = {}}
-- NetConfig.AliyunSecurityIPSdkServerGroup = {CN = {{"192.168.128.129","192.168.128.129"},{"192.168.128.129","192.168.128.129"}},EN = {{}}}
NetConfig.AliyunNetDelayDelta = 80 -- 游戏盾允许的最大延迟差
NetConfig.ResponseCodeOk = 200

NetConfig.HttpRequestTimeOut = 5
NetConfig.TcpRequestTimeOut = 5000

NetConfig.DnsResolveTimeOut = 5
NetConfig.SocketConnectTestTimeOut = 5

NetConfig.GetAliyunIpTimeOut = 5

function NetConfig.IsHeart(id1, id2)
	-- return false
	return id1 == 1 and id2 == 10
end

function NetConfig.GenerateDynamicKey()
    local timestamp = os.time()  -- ✅ ใช้เวลาปัจจุบัน
    local t = math.floor(timestamp / 300)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local key = ""
    
    local hash = (t * 1337) % 10000000
    
    for i = 0, 31 do
        hash = (hash * 1664525 + 1013904223) % 4294967296
        local seed = hash % string.len(chars)
        key = key .. string.sub(chars, seed + 1, seed + 1)
    end
   
    return key, timestamp
end

function NetConfig.IsCare(id1, id2)
	-- if id1 == 5 and id2 == 23 then
	-- 	return true
	-- end
	-- if id1 == 5 and id2 == 37 then
	-- 	return true
	-- end
	return false
end

NetConfig.NoPbUnpack = {

}

function NetConfig.IsNoPbUnpack(id1, id2)
	for i=1,#NetConfig.NoPbUnpack do
		local single = NetConfig.NoPbUnpack[i]
		if(single.id1 == id1 and single.id2 == id2)then
			return true
		end
	end
	return false
end
