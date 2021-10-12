-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('Scenario', {
	'name', "GenericAnomalies",
	'file_name', "GenericAnomalies",
	'singleton', false,
}, {
	PlaceObj('ScenarioSequence', {
		'name', "Rare Resource - Sulphides",
	}, {
		PlaceObj('SA_WaitChoice', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7156, --[[voice:narrator]] "You’d think the Explorer had found buried treasure, the way our scientists were reacting. It was a sulfur-rich regolith!"),
			'text', T(5774, --[[Scenario Anomalies text]] "The Explorer vehicle gathered various soil samples from far and wide around the Anomaly site and fed us the data. For hours, the telemetry was filled with buzzing chatter as the scientists at Mission Control discussed the implications of the element and made inventive plans about the future. The time of the expedition was limited and we urged them to make a final decision."),
			'log_entry', true,
			'image', "UI/Messages/deposits.tga",
			'choice1', T(5775, --[[Scenario Anomalies choice1]] "Concentrate effort on gathering as many samples as possible. (<research(1000)>)"),
			'choice1_img', "UI/CommonNew/message_1.tga",
			'choice2', T(5777, --[[Scenario Anomalies choice2]] "Focus on geochemical analysis of the most Sulphide-rich samples. (Reduces the cost of Engineering techs by 10%)"),
			'choice2_img', "UI/CommonNew/message_2.tga",
		}),
		PlaceObj('SA_WaitChoiceCheck', {
			'sa_id', 1,
			'end_block', 2,
		}),
		PlaceObj('SA_GrantResearchPts', nil),
		PlaceObj('SA_Block', {
			'sa_id', 2,
			'parent', 1,
		}),
		PlaceObj('SA_WaitChoiceCheck', {
			'sa_id', 3,
			'end_block', 4,
			'value', 2,
		}),
		PlaceObj('SA_GrantTechBoost', {
			'Field', "Engineering",
			'Amount', 10,
		}),
		PlaceObj('SA_Block', {
			'sa_id', 4,
			'parent', 3,
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Rare Resource - Chromium",
	}, {
		PlaceObj('SA_WaitChoice', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7159, --[[voice:narrator]] "Our initial spectrographic analysis confirmed it. Chromium. To find such a rich deposit of such a rare metal. Important was an understatement."),
			'text', T(5785, --[[Scenario Anomalies text]] "The geological team couldn't wait to get their hands on the samples, but this was going to prevent the engineering team from smelting the materials for their ceaseless operations. The experts at Mission Control argued for hours, but the course of action was clear."),
			'log_entry', true,
			'image', "UI/Messages/deposits_2.tga",
			'choice1', T(5786, --[[Scenario Anomalies choice1]] "Study the Chromium deposit. (Reduces the cost of Engineering techs by 10%)"),
			'choice1_img', "UI/CommonNew/message_1.tga",
			'choice2', T(5788, --[[Scenario Anomalies choice2]] "Exploit the deposit. (deep Rare Metals deposit)"),
			'choice2_img', "UI/CommonNew/message_2.tga",
		}),
		PlaceObj('SA_WaitChoiceCheck', {
			'sa_id', 1,
			'end_block', 2,
		}),
		PlaceObj('SA_GrantTechBoost', {
			'Field', "Engineering",
			'Amount', 10,
		}),
		PlaceObj('SA_Block', {
			'sa_id', 2,
			'parent', 1,
		}),
		PlaceObj('SA_WaitChoiceCheck', {
			'sa_id', 3,
			'end_block', 4,
			'value', 2,
		}),
		PlaceObj('SA_SpawnDepositAtAnomaly', {
			'resource', "PreciousMetals",
			'amount', 700000,
			'grade', "High",
			'depth_layer', 2,
		}),
		PlaceObj('SA_Block', {
			'sa_id', 4,
			'parent', 3,
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Rare Resource - Beryllium",
	}, {
		PlaceObj('SA_WaitMessage', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7160, --[[voice:narrator]] "Someone joked we found kryptonite. It was because of the greenish-yellow hue of the beryl crystals."),
			'text', T(5790, --[[Scenario Anomalies text]] "The contrast with the red Martian dust made them appear almost alien. Even if they wouldn't make any of the Colonists superhuman, they would surely give us almost supernatural powers!\n\nOur plans at Mission Control included the introduction of a long-term nuclear energy solution for the growing Colony, and the Beryllium that we would produce from these minerals would be an immense help in this difficult mission. We would encase the nuclear fuel rods of our nuclear reactors in Beryllium and make a good use of its incredible mechanical, chemical and nuclear properties.\n\n<effect>Reduces the cost of Physics techs by 10%."),
			'log_entry', true,
			'image', "UI/Messages/deposits_2.tga",
			'choice1', T(5791, --[[Scenario Anomalies choice1]] "Awesome!"),
		}),
		PlaceObj('SA_GrantTechBoost', {
			'Field', "Physics",
			'Amount', 10,
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Rare Resource - Tellurium",
	}, {
		PlaceObj('SA_WaitMessage', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7161, --[[voice:narrator]] "The rover manipulators held the silver-white mineral up to the camera just as the chemical analysis came through. We’ve found Tellurium."),
			'text', T(5792, --[[Scenario Anomalies text]] "In a moment, the Chief Engineer at Mission Control was at the communications station, urging instructions to the RC Explorer on how to handle and analyze the discovery. It was amusing to watch the almost childlike excitement in the eyes of the expert.\n\nThis is a significant discovery because it allows us to overcome an old problem in metallurgy. Easily-machinable metals allow for economical manufacturing of components, but the factors that allow it usually lower their performance, and vice versa. Thus, engineers had always been challenged to find ways to balance the two factors. The addition of Tellurium to iron alloys allows them to perform better in both areas.\n\n<effect>Reduces the cost of Robotics techs by 10%."),
			'log_entry', true,
			'image', "UI/Messages/deposits_2.tga",
			'choice1', T(5793, --[[Scenario Anomalies choice1]] "Great news!"),
		}),
		PlaceObj('SA_GrantTechBoost', {
			'Field', "Robotics",
			'Amount', 10,
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Magnesium Sulphates",
	}, {
		PlaceObj('SA_WaitMessage', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7163, --[[voice:narrator]] "The probe’s drill had hit one hundred meters before it detected a spike in temperature. The data tells us it was ignited Magnesium compounds."),
			'text', T(5795, --[[Scenario Anomalies text]] "We are still waiting for confirmation but the preliminary results are clear. There are signs of chemical burning, indicating a combustible material in contact with the probe. The mechanical friction of the drilling head must have ignited the magnesium. What a great discovery!\n\nScientists on Earth had long planned the creation of jet engines that could burn the carbon dioxide in the Martian atmosphere with the use of magnesium powder. With abundant amounts on site, the research teams could begin preliminary testing of a working prototype right away!\n\n<effect>Reduces the cost of Robotics techs by 10%."),
			'log_entry', true,
			'image', "UI/Messages/deposits.tga",
		}),
		PlaceObj('SA_GrantTechBoost', {
			'Field', "Robotics",
			'Amount', 10,
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Underground Cavity",
	}, {
		PlaceObj('SA_WaitMessage', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7165, --[[voice:narrator]] "We’ve just confirmed the location of a metal-rich deposit. A drilling accident turned to our advantage."),
			'text', T(5797, --[[Scenario Anomalies text]] "We lost a drilling probe while trying to analyze this Anomaly. The signal was suddenly lost and we got the tingling feeling that we would get lucky with the second one. The operators were extra careful and the second insertion revealed a vast network of underground cavities beneath the hard rock plate. On top of that, we managed to get in contact with the first probe which had fallen through in another section of the crust faults. We used the two probes as triangulation points for telemetry and pinpointed the location of the deposit.\n\n<effect>Discovered a Metal deposit."),
			'log_entry', true,
			'image', "UI/Messages/exploration.tga",
		}),
		PlaceObj('SA_SpawnDepositAtAnomaly', {
			'resource', "Metals",
			'amount', 1000000,
			'grade', "Very High",
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Rare Resource - Iridium",
	}, {
		PlaceObj('SA_WaitMessage', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7171, --[[voice:narrator]] "The analysis tells us that we’ve found Iridium-rich sulfides! That’s a real rarity on Earth!"),
			'text', T(5814, --[[Scenario Anomalies text]] "Mankind's ingenuity had found a myriad of applications for it. But we focused our plan on a much simpler, more vital role in our growing Colony – RTGs. Free energy for everyone!\n\n<effect>Reduces the cost of Physics techs by 10%."),
			'log_entry', true,
			'image', "UI/Messages/exploration_2.tga",
			'choice1', T(5815, --[[Scenario Anomalies choice1]] "Excellent!"),
		}),
		PlaceObj('SA_GrantTechBoost', {
			'Field', "Physics",
			'Amount', 10,
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Electromagnetic Concentration",
	}, {
		PlaceObj('SA_Exec', {
			'expression', 'if rover then rover:SetCommand("Malfunction") end',
		}),
		PlaceObj('SA_WaitMessage', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7172, --[[voice:narrator]] "The Rover went dark for five hours. When it rebooted, it confirmed it had come into contact with an unusually high-voltage electrical charge."),
			'text', T(5816, --[[Scenario Anomalies text]] "The red alert was sounded immediately after we lost contact with the RC Explorer vehicle. Five long hours of fear and desperation ended with the reinstating of data feed. A wave of relief passed through the crowd of scientists gathered at the control center. The telescopic drill used to probe the crust at the Anomaly site disturbed a layer of magnetite-rich rocks, the source of the electric charge. The rover is still functional but it would take time before its locomotion systems are fully restored. The operators turned the defeat into a victory, devoting the unexpected time window to studying the magnetic properties of the Martian crust.\n\n<effect>The RC Explorer has malfunctioned. It has to be repaired by Drones.\n<effect>50% cost reduction for the following technologies: Low-G Drive (faster Drones and Rovers), Autonomous Sensors (Sensor Towers require no Power or Maintenance).\n<effect> Gain <funding(200000000)> Funding."),
			'log_entry', true,
			'image', "UI/Messages/dust_storm.tga",
		}),
		PlaceObj('SA_GrantTechBoost', {
			'Field', "Robotics",
			'Research', "LowGDrive",
			'Amount', 50,
		}),
		PlaceObj('SA_GrantTechBoost', {
			'Field', "Physics",
			'Research', "AutonomousSensors",
			'Amount', 50,
		}),
		PlaceObj('SA_ChangeFunding', {
			'funding', "200000000",
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Rare metals in meteor",
	}, {
		PlaceObj('SA_WaitMessage', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7176, --[[voice:narrator]] "We found some useful material in the debris from a small meteorite."),
			'text', T(5824, --[[Scenario Anomalies text]] "After minimal processing, the resources can be transported and put to good use for the benefit of the Colony.\n\n<effect> We discovered 30 Rare Metals at the Anomaly site."),
			'log_entry', true,
			'image', "UI/Messages/crater.tga",
			'choice1', T(5825, --[[Scenario Anomalies choice1]] "Every little bit helps."),
		}),
		PlaceObj('SA_Exec', {
			'expression', 'PlaceResourceStockpile_Delayed(anomaly_pos, map_id, "PreciousMetals", 30 * const.ResourceScale, 0, true)',
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Geological Composition",
	}, {
		PlaceObj('SA_WaitMessage', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7180, --[[voice:narrator]] "Though initially fruitless, we recalibrated the operating spectrum for our scans and voila!"),
			'text', T(5837, --[[Scenario Anomalies text]] "The unusual chemical composition of the regolith near the Anomaly site effectively shielded it from our data gathering. As we re-purposed and improved our scanning technology based on these new findings, we were rewarded with an unexpected surprise.\n\n<effect>Large Water deposit discovered."),
			'log_entry', true,
			'image', "UI/Messages/exploration_2.tga",
		}),
		PlaceObj('SA_SpawnDepositAtAnomaly', {
			'resource', "Water",
			'amount', 20000000,
			'grade', "Very High",
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Alien Artifact",
	}, {
		PlaceObj('SA_Exec', {
			'expression', "funding_reward = 400000000",
		}),
		PlaceObj('SA_WaitMessage', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7182, --[[voice:narrator]] "We discovered unusual crystals in the remains of a meteorite. The magnified images of their crystalline matrix were broadcast by every major news channel on Earth."),
			'text', T(5839, --[[Scenario Anomalies text]] 'One tabloid even claims that the crystal is in fact artificially created - some kind of artwork of a microscopic alien race.\n\n"The work resembles million tiny cylinders surrounded by flames. If you squint your eyes, the very static of the composition resembles a star map. The image is bordered by double rainbows while the work has an abstract feeling and a very dynamic structure."\n\nWhile all this unscientific sensationalism had outraged our experts, the publicity provided us with some unexpected benefits.\n\n<effect>You gain <funding(reg_param1)>.'),
			'log_entry', true,
			'image', "UI/Messages/crater.tga",
			'reg_param1', "funding_reward",
			'choice1', T(5840, --[[Scenario Anomalies choice1]] "I want to believe!"),
		}),
		PlaceObj('SA_ChangeFunding', {
			'funding', "funding_reward",
		}),
		}),
	PlaceObj('ScenarioSequence', {
		'name', "Nothing",
	}, {
		PlaceObj('SA_WaitMessage', {
			'title', T(5614, --[[Scenario Anomalies title]] "Anomaly Analyzed"),
			'voiced_text', T(7183, --[[voice:narrator]] "The Explorer made a thorough scan of the Anomaly site but couldn't find anything unusual."),
			'text', T(5841, --[[Scenario Anomalies text]] "Regrettably, it appears that the unusual readings were just a sensor glitch."),
			'log_entry', true,
			'image', "UI/Messages/exploration.tga",
			'choice1', T(5842, --[[Scenario Anomalies choice1]] "Or were they?"),
		}),
		}),
	})