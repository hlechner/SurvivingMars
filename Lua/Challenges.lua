DefineClass.Challenges = {
	challenge_thread = false,
	challenge_timeout_thread = false,
}

function Challenges.CopyMove(self, other)
	CopyMoveClassFields(other, self,
	{
		"challenge_thread",
		"challenge_timeout_thread",
	})
end

function Challenges:StartChallenge()
	local challenge = g_CurrentMissionParams.challenge_id and Presets.Challenge.Default[g_CurrentMissionParams.challenge_id]
	if not challenge then
		return
	end
	
	TelemetryChallengeStart(challenge.id)
	
	local params_tbl = {
		start_time = 0, 
		expiration = challenge.time_completed,
		rollover_title = challenge.title,
		rollover_text = challenge.description,
	}
	if challenge.TrackProgress then
		params_tbl.current = 0
		params_tbl.target = challenge.TargetValue
	end
	params_tbl.rollover_text = challenge:GetChallengeDescriptionProgressText(params_tbl)
	
	self.challenge_thread = CreateGameTimeThread(function(challenge, params_tbl)
		local regs = {}
		if challenge.Init then
			challenge:Init(regs)
		end
		if challenge.mystery then
			UIColony.mystery_id = challenge.mystery
			UIColony:InitMysteries()
		end
		if challenge.TrackProgress then
			while GameTime() < challenge.time_completed do
				local progress = challenge:TickProgress(regs)
				if progress >= challenge.TargetValue and (not challenge.WinCondition or challenge:WinCondition(regs)) then
					break -- win
				elseif progress ~= params_tbl.current then
					params_tbl.current = progress
					params_tbl.rollover_text = challenge:GetChallengeDescriptionProgressText(params_tbl)
					AddOnScreenNotification("ChallengeTimer", nil, params_tbl)
				end
			end
		else	
			challenge:Run()
		end
		
		if IsValidThread(self.challenge_timeout_thread) then
			DeleteThread(self.challenge_timeout_thread)			
		end
		RemoveOnScreenNotification("ChallengeTimer")
		
		if GameTime() <= challenge.time_completed then
			local score = 0
			ForEachPreset("Milestone", function(o)
				local cs = o:GetChallengeScore()
				if cs then
					score = score + cs
				end
			end)
			
			AccountStorage.CompletedChallenges = AccountStorage.CompletedChallenges or {}
			local record = AccountStorage.CompletedChallenges[challenge.id]
			if type(record) ~= "table" or record.time > GameTime() then
				record = {
					time = GameTime(),
					score = score,
				}
				AccountStorage.CompletedChallenges[challenge.id] = record
				SaveAccountStorage(5000)
			end
			local perfected = GameTime() <= challenge.time_perfected
			Msg("ChallengeCompleted", challenge, perfected)
			while true do
				local preset = perfected and "Challenge_Perfected" or "Challenge_Completed"
				local res = WaitPopupNotification(preset, {
					challenge_name = challenge.title,
					challenge_sols = challenge.time_completed / const.DayDuration,
					perfected_sols = challenge.time_perfected / const.DayDuration,
					elapsed_sols = 1+ GameTime() / const.DayDuration,
					score = score,
				})
				if res == 1 then
					TelemetryChallengeEnd(challenge.id, perfected and "perfected" or "completed", true)
					CreateRealTimeThread(GallerySaveDefaultScreenshot, challenge.id)
					WaitMsg("ChallengeDefaultScreenshotSaved")
					break -- keep playing
				elseif res == 2 then
					g_PhotoModeChallengeId = challenge.id
					StartPhotoMode()
					WaitMsg("ChallengeScreenshotSaved")
				elseif res == 3 then
					CreateRealTimeThread(function()
						LoadingScreenOpen("idLoadingScreen", "challenge completed")
						TelemetryChallengeEnd(challenge.id, perfected and "perfected" or "completed", false)
						GallerySaveDefaultScreenshot(challenge.id)
						OpenPreGameMainMenu()
						LoadingScreenClose("idLoadingScreen", "challenge completed")
					end)
					break
				end
			end
		end
	end, challenge, params_tbl)
	
	self.challenge_timeout_thread = CreateGameTimeThread(function(self, challenge, params_tbl)
		-- add notification with countdown
		params_tbl.expiration2 = challenge.time_perfected
		params_tbl.additional_text = T(10489, "<newline>Perfect time: <countdown2>")
		if challenge.TrackProgress then
			params_tbl.rollover_text = challenge:GetChallengeDescriptionProgressText(params_tbl)
		end
		AddOnScreenNotification("ChallengeTimer", nil, params_tbl)
		Sleep(challenge.time_perfected)
		params_tbl.expiration2 = nil
		params_tbl.additional_text = nil
		if challenge.TrackProgress then
			params_tbl.rollover_text = challenge:GetChallengeDescriptionProgressText(params_tbl)
		end
		AddOnScreenNotification("ChallengeTimer", nil, params_tbl)
		Sleep(challenge.time_completed - challenge.time_perfected)
		RemoveOnScreenNotification("ChallengeTimer")
					
		if IsValidThread(self.challenge_thread) then
			DeleteThread(self.challenge_thread)
		end
		
		-- popup fail message, exit to main menu if the player chooses
		local res = WaitPopupNotification("Challenge_Failed", {
					challenge_name = challenge.title,
					challenge_sols = challenge.time_completed / const.DayDuration,
					perfected_sols = challenge.time_perfected / const.DayDuration,
					elapsed_sols = 1 + GameTime() / const.DayDuration,
				})
		if res == 3 then
			TelemetryChallengeEnd(challenge.id, "failed", false)
			CreateRealTimeThread(OpenPreGameMainMenu)
		elseif res == 2 then
			TelemetryChallengeEnd(challenge.id, "failed", false)
			CreateRealTimeThread(function()
				LoadingScreenOpen("idLoadingScreen", "restart map")
				TelemetryRestartSession()
				g_SessionSeed = g_InitialSessionSeed
				g_RocketCargo = g_InitialRocketCargo
				g_CargoCost = g_InitialCargoCost
				g_CargoWeight = g_InitialCargoWeight
				GenerateCurrentRandomMap()
				LoadingScreenClose("idLoadingScreen", "restart map")
			end)
		else
			TelemetryChallengeEnd(challenge.id, "failed", true)
		end
	end, self, challenge, params_tbl)
end
