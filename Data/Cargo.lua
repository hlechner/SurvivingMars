-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('Cargo', {
	SortKey = 2001000,
	description = T(4477, --[[Cargo RCRover description]] "Remote-controlled vehicle that transports, commands and repairs Drones."),
	group = "Rovers",
	icon = "UI/Icons/Payload/RCRover.tga",
	id = "RCRover",
	kg = 10000,
	name = T(7678, --[[Cargo RCRover name]] "RC Commander"),
	price = 300000000,
})

PlaceObj('Cargo', {
	SortKey = 2002000,
	description = T(4455, --[[Cargo ExplorerRover description]] "A remote-controlled exploration vehicle that can analyze Anomalies."),
	group = "Rovers",
	icon = "UI/Icons/Payload/RCExplorer.tga",
	id = "ExplorerRover",
	kg = 10000,
	name = T(1684, --[[Cargo ExplorerRover name]] "RC Explorer"),
	price = 400000000,
})

PlaceObj('Cargo', {
	SortKey = 2003000,
	description = T(4461, --[[Cargo RCTransport description]] "Remote-controlled vehicle that transports resources. Use it to establish permanent supply routes or to gather resources from surface deposits."),
	group = "Rovers",
	icon = "UI/Icons/Payload/RCTransport.tga",
	id = "RCTransport",
	kg = 10000,
	name = T(1683, --[[Cargo RCTransport name]] "RC Transport"),
	price = 200000000,
})

PlaceObj('Cargo', {
	SortKey = 2004000,
	description = T(12651, --[[Cargo RCSafari description]] "Remote-controlled vehicle that takes Tourists on a Safari. Configure a route with waypoints near interesting sights to increase the Satisfaction awarded to Tourists."),
	group = "Rovers",
	icon = "UI/Icons/Payload/RCSafari.tga",
	id = "RCSafari",
	kg = 10000,
	name = T(12652, --[[Cargo RCSafari name]] "RC Safari"),
	price = 500000000,
})

PlaceObj('Cargo', {
	SortKey = 2009000,
	description = T(4390, --[[Cargo Drone description]] "An automated unit controlled by a Drone Hub, Rocket or RC Commander. Gathers resources, constructs buildings and performs maintenance."),
	group = "Rovers",
	icon = "UI/Icons/Payload/Drone.tga",
	id = "Drone",
	max = 20,
	name = T(1681, --[[Cargo Drone name]] "Drone"),
	price = 30000000,
})

PlaceObj('Cargo', {
	SortKey = 3001000,
	description = T(7910, --[[Cargo Metals description]] "Basic construction materials often used to construct and maintain outside buildings. Required for the creation of Machine Parts."),
	group = "Basic Resources",
	id = "Metals",
	name = T(3514, --[[Cargo Metals name]] "Metals"),
	price = 10000000,
})

PlaceObj('Cargo', {
	SortKey = 3002000,
	description = T(7909, --[[Cargo Concrete description]] "Basic construction material often used to construct and maintain Domes and Dome buildings."),
	group = "Basic Resources",
	id = "Concrete",
	name = T(3513, --[[Cargo Concrete name]] "Concrete"),
	price = 6000000,
})

PlaceObj('Cargo', {
	SortKey = 3003000,
	description = T(7914, --[[Cargo Food description]] "Colonists arrive with nominal Food supply, but will soon need additional provisions to survive."),
	group = "Basic Resources",
	id = "Food",
	kg = 400,
	name = T(1022, --[[Cargo Food name]] "Food"),
	price = 4000000,
})

PlaceObj('Cargo', {
	SortKey = 4006000,
	description = T(14359, --[[Cargo WasteRock description]] "Waste materials usually introduced as a byproduct of mining and landscaping activities."),
	group = "Other Resources",
	hidden = true,
	id = "WasteRock",
	kg = 800,
	name = T(4518, --[[Cargo WasteRock name]] "Waste Rock"),
	price = 12000000,
})

PlaceObj('Cargo', {
	SortKey = 4001000,
	description = T(7911, --[[Cargo Polymers description]] "Advanced materials often used to construct and maintain Power accumulators, advanced Power generators, Domes and Spires."),
	group = "Advanced Resources",
	id = "Polymers",
	kg = 400,
	name = T(3515, --[[Cargo Polymers name]] "Polymers"),
	price = 14000000,
})

PlaceObj('Cargo', {
	SortKey = 4002000,
	description = T(7913, --[[Cargo MachineParts description]] "Advanced materials often used to construct and maintain Extractors and Factories."),
	group = "Advanced Resources",
	id = "MachineParts",
	kg = 400,
	name = T(3516, --[[Cargo MachineParts name]] "Machine Parts"),
	price = 18000000,
})

PlaceObj('Cargo', {
	SortKey = 4003000,
	description = T(7986, --[[Cargo Fuel description]] "Advanced resource produced in Fuel Refineries from Water. Required for the refuelling of Rockets. Highly explosive."),
	group = "Advanced Resources",
	hidden = true,
	id = "Fuel",
	kg = 800,
	name = T(4765, --[[Cargo Fuel name]] "Fuel"),
	price = 20000000,
})

PlaceObj('Cargo', {
	SortKey = 4003500,
	description = T(7912, --[[Cargo Electronics description]] "Advanced materials often used to construct and maintain scientific and infrastructure buildings."),
	group = "Advanced Resources",
	id = "Electronics",
	kg = 400,
	name = T(3517, --[[Cargo Electronics name]] "Electronics"),
	price = 20000000,
})

PlaceObj('Cargo', {
	SortKey = 5001000,
	description = T(10277, --[[Cargo OrbitalProbe description]] "Reveals underground deposits in the scanned area."),
	group = "Probe",
	id = "OrbitalProbe",
	name = T(3525, --[[Cargo OrbitalProbe name]] "Orbital Probe"),
})

PlaceObj('Cargo', {
	SortKey = 10010000,
	description = T(5049, --[[Cargo DroneHub description]] "Controls Drones and allocates them to different tasks."),
	group = "Prefabs",
	icon = "UI/Icons/Payload/DroneHub.tga",
	id = "DroneHub",
	kg = 5000,
	name = T(3518, --[[Cargo DroneHub name]] "Drone Hub"),
	price = 150000000,
})

PlaceObj('Cargo', {
	SortKey = 10030000,
	description = T(5076, --[[Cargo FuelFactory description]] "Produces Fuel from Water."),
	group = "Prefabs",
	icon = "UI/Icons/Payload/FuelFactory.tga",
	id = "FuelFactory",
	kg = 5000,
	name = T(5074, --[[Cargo FuelFactory name]] "Fuel Refinery"),
	price = 200000000,
})

PlaceObj('Cargo', {
	SortKey = 10030000,
	description = T(5174, --[[Cargo MoistureVaporator description]] "Produces Water from the atmosphere. Production lowered when placed near other Vaporators. No production during Dust Storms."),
	group = "Prefabs",
	icon = "UI/Icons/Payload/MoistureVaporator.tga",
	id = "MoistureVaporator",
	kg = 5000,
	name = T(3519, --[[Cargo MoistureVaporator name]] "Moisture Vaporator"),
	price = 200000000,
})

PlaceObj('Cargo', {
	SortKey = 10040000,
	description = T(5289, --[[Cargo StirlingGenerator description]] "Generates Power. While closed the generator is protected from dust, but produces less power."),
	group = "Prefabs",
	icon = "UI/Icons/Payload/StirlingGenerator.tga",
	id = "StirlingGenerator",
	kg = 2000,
	name = T(3521, --[[Cargo StirlingGenerator name]] "Stirling Generator"),
	price = 400000000,
})

PlaceObj('Cargo', {
	SortKey = 10081000,
	description = T(5200, --[[Cargo PolymerPlant description]] "Produces Polymers from Water and Fuel."),
	group = "Prefabs",
	icon = "UI/Icons/Payload/PolymerPlant.tga",
	id = "PolymerPlant",
	kg = 10000,
	name = T(3524, --[[Cargo PolymerPlant name]] "Polymer Factory"),
	price = 300000000,
})

PlaceObj('Cargo', {
	SortKey = 10081020,
	description = T(5132, --[[Cargo MachinePartsFactory description]] "Produces Machine Parts from Metals."),
	group = "Prefabs",
	icon = "UI/Icons/Payload/MachinePartsFactory.tga",
	id = "MachinePartsFactory",
	kg = 10000,
	name = T(3522, --[[Cargo MachinePartsFactory name]] "Machine Parts Factory"),
	price = 400000000,
})

PlaceObj('Cargo', {
	SortKey = 10081040,
	description = T(5060, --[[Cargo ElectronicsFactory description]] "Creates Electronics from Rare Metals."),
	group = "Prefabs",
	icon = "UI/Icons/Payload/ElectronicsFactory.tga",
	id = "ElectronicsFactory",
	kg = 10000,
	name = T(3523, --[[Cargo ElectronicsFactory name]] "Electronics Factory"),
	price = 600000000,
})

PlaceObj('Cargo', {
	SortKey = 10011000,
	description = T(5261, --[[Cargo ShuttleHub description]] "Houses and refuels Shuttles that facilitate long-range resource transportation between Depots and resettling of Colonists between Domes."),
	group = "Locked",
	id = "ShuttleHub",
	kg = 10000,
	locked = true,
	name = T(3526, --[[Cargo ShuttleHub name]] "Shuttle Hub"),
	price = 1000000000,
})

PlaceObj('Cargo', {
	SortKey = 10060000,
	description = T(5307, --[[Cargo WaterExtractor description]] "Extracts Water from underground deposits. All extractors contaminate nearby buildings with dust."),
	group = "Locked",
	id = "WaterExtractor",
	kg = 5000,
	locked = true,
	name = T(3529, --[[Cargo WaterExtractor name]] "Water Extractor"),
	price = 150000000,
})

PlaceObj('Cargo', {
	SortKey = 10080000,
	description = T(5160, --[[Cargo MetalsExtractor description]] "Extracts Metals from underground deposits. All extractors contaminate nearby buildings with dust."),
	group = "Locked",
	id = "MetalsExtractor",
	kg = 5000,
	locked = true,
	name = T(3527, --[[Cargo MetalsExtractor name]] "Metals Extractor"),
	price = 200000000,
})

PlaceObj('Cargo', {
	SortKey = 10080010,
	description = T(5034, --[[Cargo RegolithExtractor description]] "Extracts sulfurous rich regolith from Concrete deposits and produces Concrete. All extractors contaminate nearby buildings with dust."),
	group = "Locked",
	id = "RegolithExtractor",
	kg = 5000,
	locked = true,
	name = T(5032, --[[Cargo RegolithExtractor name]] "Concrete Extractor"),
	price = 150000000,
})

PlaceObj('Cargo', {
	SortKey = 10080020,
	description = T(5224, --[[Cargo PreciousMetalsExtractor description]] "Extracts Rare Metals from underground deposits. All extractors contaminate nearby buildings with dust."),
	group = "Locked",
	id = "PreciousMetalsExtractor",
	kg = 5000,
	locked = true,
	name = T(3530, --[[Cargo PreciousMetalsExtractor name]] "Rare Metals Extractor"),
	price = 200000000,
})

PlaceObj('Cargo', {
	SortKey = 10090000,
	description = T(5007, --[[Cargo Apartments description]] "Provides living space for Colonists. Cramped quarters grant less Comfort during rest."),
	group = "Locked",
	id = "Apartments",
	kg = 10000,
	locked = true,
	name = T(3531, --[[Cargo Apartments name]] "Apartments"),
	price = 200000000,
})

PlaceObj('Cargo', {
	SortKey = 10090010,
	description = T(5122, --[[Cargo LivingQuarters description]] "Provides living space. Resting residents recover Comfort faster compared to other Residences."),
	group = "Locked",
	id = "LivingQuarters",
	kg = 10000,
	locked = true,
	name = T(3532, --[[Cargo LivingQuarters name]] "Living Complex"),
})

PlaceObj('Cargo', {
	SortKey = 10090020,
	description = T(5273, --[[Cargo SmartHome description]] "Provide a very comfortable living space for Colonists. Residents will recover additional Sanity when resting."),
	group = "Locked",
	id = "SmartHome",
	kg = 10000,
	locked = true,
	name = T(7800, --[[Cargo SmartHome name]] "Smart Complex"),
	price = 300000000,
})

PlaceObj('Cargo', {
	SortKey = 10100000,
	description = T(5009, --[[Cargo Arcology description]] "Provides living space for numerous Colonists, granting high Comfort."),
	group = "Locked",
	icon = "UI/Icons/Payload/Arcology.tga",
	id = "Arcology",
	kg = 20000,
	locked = true,
	name = T(3534, --[[Cargo Arcology name]] "Arcology"),
	price = 700000000,
})

PlaceObj('Cargo', {
	SortKey = 10100010,
	description = T(5099, --[[Cargo HangingGardens description]] "A beautiful park complex. Increases the Comfort of all Residences in the Dome."),
	group = "Locked",
	icon = "UI/Icons/Payload/HangingGardens.tga",
	id = "HangingGardens",
	kg = 20000,
	locked = true,
	name = T(3535, --[[Cargo HangingGardens name]] "Hanging Gardens"),
	price = 400000000,
})

PlaceObj('Cargo', {
	SortKey = 10100020,
	description = T(5309, --[[Cargo WaterReclamationSystem description]] "Recycles up to 70% of the Water used in the Dome."),
	group = "Locked",
	icon = "UI/Icons/Payload/WaterReclamationSystem.tga",
	id = "WaterReclamationSystem",
	kg = 20000,
	locked = true,
	name = T(3536, --[[Cargo WaterReclamationSystem name]] "Water Reclamation System"),
	price = 500000000,
})

PlaceObj('Cargo', {
	SortKey = 10100030,
	description = T(5025, --[[Cargo CloningVats description]] "Creates Clones over time. Cloned Colonists grow and age twice as fast."),
	group = "Locked",
	icon = "UI/Icons/Payload/CloningVats.tga",
	id = "CloningVats",
	kg = 20000,
	locked = true,
	name = T(3537, --[[Cargo CloningVats name]] "Cloning Vats"),
	price = 700000000,
})

PlaceObj('Cargo', {
	SortKey = 10100040,
	description = T(5178, --[[Cargo NetworkNode description]] "Increases the overall Research output of the Dome."),
	group = "Locked",
	icon = "UI/Icons/Payload/NetworkNode.tga",
	id = "NetworkNode",
	kg = 20000,
	locked = true,
	name = T(3538, --[[Cargo NetworkNode name]] "Network Node"),
	price = 600000000,
})

PlaceObj('Cargo', {
	SortKey = 10100050,
	description = T(5143, --[[Cargo MedicalCenter description]] "Visitors will recover Health and Sanity as long as they are not starving, dehydrated, freezing or suffocating. Larger capacity and more effective than the Infirmary. A Dome with a Medical Building has lower minimum Comfort requirement for births."),
	group = "Locked",
	icon = "UI/Icons/Payload/MedicalCenter.tga",
	id = "MedicalCenter",
	kg = 20000,
	locked = true,
	name = T(3539, --[[Cargo MedicalCenter name]] "Medical Center"),
	price = 500000000,
})

PlaceObj('Cargo', {
	SortKey = 10100060,
	description = T(5246, --[[Cargo Sanatorium description]] "Treats Colonists for flaws through advanced and (mostly) humane medical practices."),
	group = "Locked",
	icon = "UI/Icons/Payload/Sanatorium.tga",
	id = "Sanatorium",
	kg = 20000,
	locked = true,
	name = T(3540, --[[Cargo Sanatorium name]] "Sanatorium"),
	price = 600000000,
})

PlaceObj('Cargo', {
	SortKey = 10012010,
	description = T(5231, --[[Cargo RechargeStation description]] "Recharges Drone batteries."),
	group = "Refab",
	id = "RechargeStation",
	locked = true,
	name = T(5229, --[[Cargo RechargeStation name]] "Recharge Station"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10041000,
	description = T(5121, --[[Cargo SolarPanel description]] "Generates Power during daytime. Closes during Dust Storms. Protected from dust while turned off."),
	group = "Refab",
	id = "SolarPanel",
	locked = true,
	name = T(5274, --[[Cargo SolarPanel name]] "Solar Panel"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10041010,
	description = T(5121, --[[Cargo SolarPanelBig description]] "Generates Power during daytime. Closes during Dust Storms. Protected from dust while turned off."),
	group = "Refab",
	id = "SolarPanelBig",
	kg = 2000,
	locked = true,
	name = T(5120, --[[Cargo SolarPanelBig name]] "Large Solar Panel"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10041030,
	description = T(5092, --[[Cargo FusionReactor description]] "Generates significant amounts of Power but requires Workers from a nearby Dome."),
	group = "Refab",
	id = "FusionReactor",
	kg = 5000,
	locked = true,
	name = T(5090, --[[Cargo FusionReactor name]] "Fusion Reactor"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10051000,
	description = T(5015, --[[Cargo AtomicBattery description]] "Stores Power. High capacity and max output, but charges slowly."),
	group = "Refab",
	id = "AtomicBattery",
	kg = 5000,
	locked = true,
	name = T(5013, --[[Cargo AtomicBattery name]] "Atomic Accumulator"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10051010,
	description = T(5207, --[[Cargo Battery_WaterFuelCell description]] "Stores Power. Amount of Power supplied is limited by the battery’s max output."),
	group = "Refab",
	id = "Battery_WaterFuelCell",
	kg = 2000,
	locked = true,
	name = T(5205, --[[Cargo Battery_WaterFuelCell name]] "Power Accumulator"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10061010,
	description = T(5129, --[[Cargo MOXIE description]] "Produces Oxygen. No production during Dust Storms."),
	group = "Refab",
	id = "MOXIE",
	kg = 5000,
	locked = true,
	name = T(5127, --[[Cargo MOXIE name]] "MOXIE"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10070000,
	description = T(5312, --[[Cargo WaterTank description]] "Stores Water. Doesn't work during Cold Waves."),
	group = "Refab",
	id = "WaterTank",
	kg = 2000,
	locked = true,
	name = T(5310, --[[Cargo WaterTank name]] "Water Tower"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10070010,
	description = T(8824, --[[Cargo LargeWaterTank description]] "Can store a large amount of Water. Doesn't work during Cold Waves."),
	group = "Refab",
	id = "LargeWaterTank",
	kg = 3000,
	locked = true,
	name = T(8822, --[[Cargo LargeWaterTank name]] "Large Water Tank"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10070020,
	description = T(5193, --[[Cargo OxygenTank description]] "Stores Oxygen."),
	group = "Refab",
	id = "OxygenTank",
	kg = 2000,
	locked = true,
	name = T(5191, --[[Cargo OxygenTank name]] "Oxygen Tank"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10083030,
	description = T(5047, --[[Cargo DroneFactory description]] "Produces Drones Prefabs which can then be used to order new drones in Drone Hubs multiplying the obedient workforce of the Colony. Probably not a threat to humans."),
	group = "Refab",
	id = "DroneFactory",
	kg = 5000,
	locked = true,
	name = T(5045, --[[Cargo DroneFactory name]] "Drone Assembler"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10083040,
	description = T(5069, --[[Cargo Farm description]] "Produces Food. Consumes Water depending on crop type."),
	group = "Refab",
	id = "Farm",
	kg = 5000,
	locked = true,
	name = T(4812, --[[Cargo Farm name]] "Farm"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10083060,
	description = T(5069, --[[Cargo HydroponicFarm description]] "Produces Food. Consumes Water depending on crop type."),
	group = "Refab",
	id = "HydroponicFarm",
	kg = 5000,
	locked = true,
	name = T(5101, --[[Cargo HydroponicFarm name]] "Hydroponic Farm"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10083110,
	description = T(10245, --[[Cargo WasteRockProcessor description]] "Slowly turns waste rock into building materials. Produces Concrete."),
	group = "Refab",
	id = "WasteRockProcessor",
	kg = 5000,
	locked = true,
	name = T(10243, --[[Cargo WasteRockProcessor name]] "Waste Rock Processor"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10091000,
	description = T(889392282896, --[[Cargo Hotel description]] "Provides living space for Tourists and Colonists. Luxurious hotel rooms that provide the best holiday experience. Tourists gain <em>Satisfaction</em> while staying here."),
	group = "Refab",
	id = "Hotel",
	kg = 10000,
	locked = true,
	name = T(426921114197, --[[Cargo Hotel name]] "Olympus Hotel"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10091030,
	description = T(5139, --[[Cargo MartianUniversity description]] "Trains Specialists using modern remote learning techniques. Graduation speed depends on the individual student performance."),
	group = "Refab",
	id = "MartianUniversity",
	kg = 10000,
	locked = true,
	name = T(5137, --[[Cargo MartianUniversity name]] "Martian University"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10091040,
	description = T(5181, --[[Cargo Nursery description]] "Provides living space for children."),
	group = "Refab",
	id = "Nursery",
	kg = 5000,
	locked = true,
	name = T(5179, --[[Cargo Nursery name]] "Nursery"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10091050,
	description = T(5198, --[[Cargo Playground description]] "Cultivates Perks in Children through special nurturing programs."),
	group = "Refab",
	id = "Playground",
	kg = 5000,
	locked = true,
	name = T(5196, --[[Cargo Playground name]] "Playground"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10091060,
	description = T(5237, --[[Cargo ResearchLab description]] "Generates Research."),
	group = "Refab",
	id = "ResearchLab",
	kg = 10000,
	locked = true,
	name = T(5235, --[[Cargo ResearchLab name]] "Research Lab"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10091070,
	description = T(5249, --[[Cargo School description]] "Cultivates desired Perks in children using modern remote learning techniques."),
	group = "Refab",
	id = "School",
	kg = 10000,
	locked = true,
	name = T(5247, --[[Cargo School name]] "School"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10091080,
	description = T(5253, --[[Cargo ScienceInstitute description]] "Generates Research faster than a Research Lab."),
	group = "Refab",
	id = "ScienceInstitute",
	kg = 10000,
	locked = true,
	name = T(5251, --[[Cargo ScienceInstitute name]] "Hawking Institute"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10091110,
	description = T(5271, --[[Cargo SmartHome_Small description]] "Provides a very comfortable living space for Colonists. Residents will recover additional Sanity when resting."),
	group = "Refab",
	id = "SmartHome_Small",
	kg = 5000,
	locked = true,
	name = T(3533, --[[Cargo SmartHome_Small name]] "Smart Home"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	group = "Refab",
	id = "Amphitheater",
	kg = 5000,
	locked = true,
	name = T(917416454692, --[[Cargo Amphitheater name]] "Amphitheater"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(8821, --[[Cargo ArtWorkshop description]] "A vocation building dedicated to creation of works of art. Workers receive Comfort and Morale boost and count towards the Workshop milestone. Consumes Polymers."),
	group = "Refab",
	id = "ArtWorkshop",
	kg = 10000,
	locked = true,
	name = T(8819, --[[Cargo ArtWorkshop name]] "Art Workshop"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(8827, --[[Cargo BioroboticsWorkshop description]] "A vocation building dedicated to the creation of Biorobots. Workers receive Comfort and Morale boost and count towards the Workshop milestone. Consumes Machine Parts."),
	group = "Refab",
	id = "BioroboticsWorkshop",
	kg = 10000,
	locked = true,
	name = T(8825, --[[Cargo BioroboticsWorkshop name]] "Biorobotics Workshop"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(5024, --[[Cargo CasinoComplex description]] "A place of luxurious entertainment and questionable morals, helping to bring out the best of humanity."),
	group = "Refab",
	id = "CasinoComplex",
	kg = 20000,
	locked = true,
	name = T(5022, --[[Cargo CasinoComplex name]] "Casino Complex"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(5044, --[[Cargo Diner description]] "Serves the finest dishes on Mars. Now featuring non-plastic tableware."),
	group = "Refab",
	id = "Diner",
	kg = 5000,
	locked = true,
	name = T(5042, --[[Cargo Diner name]] "Diner"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(5107, --[[Cargo Infirmary description]] "Visitors will recover Health and Sanity as long as they are not starving, dehydrated, freezing or suffocating. A Dome with a Medical Building has lower minimum Comfort requirement for births."),
	group = "Refab",
	id = "Infirmary",
	kg = 5000,
	locked = true,
	name = T(5105, --[[Cargo Infirmary name]] "Infirmary"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(405184452773, --[[Cargo LowGAmusementPark description]] "Provides thrills and opportunities to socialize for all Colonists. Tourists gain <em>Satisfaction</em> from visits."),
	group = "Refab",
	id = "LowGAmusementPark",
	kg = 20000,
	locked = true,
	name = T(687053338060, --[[Cargo LowGAmusementPark name]] "Low-G Amusement Park"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(5187, --[[Cargo OpenAirGym description]] "Visitors recover a small amount of Health and may become Fit."),
	group = "Refab",
	id = "OpenAirGym",
	kg = 10000,
	locked = true,
	name = T(5185, --[[Cargo OpenAirGym name]] "Open Air Gym"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(5256, --[[Cargo SecurityStation description]] "Counters crime by Renegades. Reduces Sanity loss from disasters for all residents. All Officers in the Dome will try to prevent crime events."),
	group = "Refab",
	id = "SecurityStation",
	kg = 5000,
	locked = true,
	name = T(5254, --[[Cargo SecurityStation name]] "Security Station"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(5067, --[[Cargo ShopsElectronics description]] "Buy the latest and greatest gadgets Mars has to offer! Consumes Electronics on each visit."),
	group = "Refab",
	id = "ShopsElectronics",
	kg = 5000,
	locked = true,
	name = T(5065, --[[Cargo ShopsElectronics name]] "Electronics Store"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(5098, --[[Cargo ShopsFood description]] "Distributes hot meals and fresh produce. Consumes Food on each visit."),
	group = "Refab",
	id = "ShopsFood",
	kg = 5000,
	locked = true,
	name = T(5096, --[[Cargo ShopsFood name]] "Grocer"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(5110, --[[Cargo ShopsJewelry description]] "A place to purchase authentic Martian works of art. Consumes Polymers on each visit."),
	group = "Refab",
	id = "ShopsJewelry",
	kg = 5000,
	locked = true,
	name = T(5108, --[[Cargo ShopsJewelry name]] "Art Store"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(5282, --[[Cargo Spacebar description]] "Provides space for R&R and fancy cocktails."),
	group = "Refab",
	id = "Spacebar",
	kg = 10000,
	locked = true,
	name = T(5280, --[[Cargo Spacebar name]] "Spacebar"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10110010,
	description = T(8818, --[[Cargo VRWorkshop description]] "A vocation building dedicated to the creation of virtual worlds. Workers receive Comfort and Morale boost and count towards the Workshop milestone. Consumes Electronics."),
	group = "Refab",
	id = "VRWorkshop",
	kg = 10000,
	locked = true,
	name = T(8816, --[[Cargo VRWorkshop name]] "VR Workshop"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10120000,
	description = T(5145, --[[Cargo GardenAlleys_Medium description]] "A beautiful park with alleys and benches."),
	group = "Refab",
	id = "GardenAlleys_Medium",
	kg = 7500,
	locked = true,
	name = T(5144, --[[Cargo GardenAlleys_Medium name]] "Alleys"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10120010,
	description = T(5116, --[[Cargo FountainLarge description]] "A place for relaxation and recreation."),
	group = "Refab",
	id = "FountainLarge",
	kg = 7500,
	locked = true,
	name = T(5114, --[[Cargo FountainLarge name]] "Fountain"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10120020,
	description = T(5151, --[[Cargo GardenNatural_Medium description]] "A recreational area with cultivated vegetation."),
	group = "Refab",
	id = "GardenNatural_Medium",
	kg = 7500,
	locked = true,
	name = T(5149, --[[Cargo GardenNatural_Medium name]] "Garden"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10120050,
	description = T(5113, --[[Cargo Lake description]] "A large pond with refreshingly cool water."),
	group = "Refab",
	id = "Lake",
	kg = 7500,
	locked = true,
	name = T(12565, --[[Cargo Lake name]] "Pond"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10120055,
	description = T(5218, --[[Cargo LampProjector description]] "Make the Martian night a little brighter."),
	group = "Refab",
	id = "LampProjector",
	kg = 500,
	locked = true,
	name = T(5216, --[[Cargo LampProjector name]] "Projector Lamp"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10120061,
	description = T(5145, --[[Cargo GardenAlleys_Small description]] "A beautiful park with alleys and benches."),
	group = "Refab",
	id = "GardenAlleys_Small",
	kg = 5000,
	locked = true,
	name = T(5262, --[[Cargo GardenAlleys_Small name]] "Small Alleys"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10120062,
	description = T(5116, --[[Cargo FountainSmall description]] "A place for relaxation and recreation."),
	group = "Refab",
	id = "FountainSmall",
	kg = 5000,
	locked = true,
	name = T(5263, --[[Cargo FountainSmall name]] "Small Fountain"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10120063,
	description = T(5151, --[[Cargo GardenNatural_Small description]] "A recreational area with cultivated vegetation."),
	group = "Refab",
	id = "GardenNatural_Small",
	kg = 5000,
	locked = true,
	name = T(5265, --[[Cargo GardenNatural_Small name]] "Small Garden"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10120065,
	description = T(5285, --[[Cargo Statue description]] '"In honor of the Founders of Mars."'),
	group = "Refab",
	id = "Statue",
	kg = 7500,
	locked = true,
	name = T(5283, --[[Cargo Statue name]] "Statue"),
	price = 999000000,
})

PlaceObj('Cargo', {
	SortKey = 10120070,
	description = T(5292, --[[Cargo GardenStone description]] "A tastefully arranged stone garden, following strict Zen rules."),
	group = "Refab",
	id = "GardenStone",
	kg = 7500,
	locked = true,
	name = T(5290, --[[Cargo GardenStone name]] "Stone Garden"),
	price = 999000000,
})

