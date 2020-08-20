Use		MilkoScanFT3;


 Create table #Settings 
 (
		ParameterLogicalID int
	,	ParameterName nvarchar(50)
	,	NumberOfDecimals int
	,	GoodProductLimit float
	,	ProductLogicalID int
	,	ProductName nvarchar(50)
	,	Intercept float
 )

 Create Table #Values
 (
		AnalysisTime datetime
	,	Result float
	,	SampleID nvarchar(50)
	,	ParameterLogicalID int
	,	InstrumentLogicalID int
	,	Median float
	,	StdDev float
	,	Cnt int
 )	


 --Insert the current values of the Good Product detection limits
 Insert Into #Settings

Select		th.ParameterLogicalID
		,	th.ShortName as ParameterName
		,	th.NumberOfDecimals
		,	th.GoodProductLimit
		,	ic.ProductLogicalID
		,	ic.ProductName
		,	IsNull(ic.Intercept, 0) as Intercept
From
(
Select			pa.ParameterLogicalID
			,	ps.NumericValue as GoodProductLimit
			,	pp.NumberOfDecimals
			,	pp.ShortName
	From		tblMfCdPredictionModelTypeSettingGroup ptsg
	Inner Join	tblMfCdPredictionModelTypeSetting pts
		on		pts.PredictionModelTypeSettingGroupID = ptsg.PredictionModelTypeSettingGroupID
	Inner Join	tblMfCdParameterSetting ps
		on		ps.PredictionModelTypeSettingID = pts.PredictionModelTypeSettingID
	Inner Join	tblMfCdParameterSettingGroup psg
		on		psg.ParameterSettingGroupID = ps.ParameterSettingGroupID
	Inner Join	tblMfCdParameter pa
		on		pa.ParameterID = psg.ParameterID
	Inner Join	tblMfCdParameterProfile pp
		on		pp.ParameterProfileLogicalID = pa.ParameterProfileLogicalID
	Where		ptsg.PredictionModelTypeID = 133
		and		ptsg.Identification = 'Threshold'
		and		pa.Obsolete = 0
		and		pp.Obsolete = 0
) th
Left join
(
	Select		pr.Name as ProductName
			,	pr.ProductLogicalID
			,	ipp.ParameterLogicalID
			,	IsNull(ipps.NumericValue, 0) as Intercept
			--,	*
	From		tblMfCdProduct pr
	Inner Join	tblMfCdInstrumentProductParameter ipp
		on		ipp.ProductLogicalID = pr.ProductLogicalID
	Inner Join	tblMfCdInstrumentProductParameterSettingGroup ippsg
		on		ippsg.InstrumentProductParameterID = ipp.InstrumentProductParameterID
	Inner Join	tblMfCdInstrumentProductParameterSetting ipps
		on		ipps.InstrumentProductParameterSettingGroupID = ippsg.InstrumentProductParameterSettingGroupID
	Inner Join	tblMfCdPredictionModelTypeSettingGroup pmtsg
		on		pmtsg.PredictionModelTypeSettingGroupID = ippsg.PredictionModelTypeSettingGroupID
	Inner Join	tblMfCdPredictionModelTypeSetting pmts
		on		pmts.PredictionModelTypeSettingGroupID = pmtsg.PredictionModelTypeSettingGroupID
		and		pmts.PredictionModelTypeSettingID = ipps.PredictionModelTypeSettingID
	Where		ipp.Obsolete = 0
		and		pr.Obsolete = 0
		and		pmts.Identification = 'Intercept'
) ic
	on		th.ParameterLogicalID = ic.ParameterLogicalID

Insert Into #Values

	Select		sa.AnalysisEndUTC
			,	pv.DoubleResult as Result
			,	sa.SampleNumber
			,	pa.ParameterLogicalID
			,	sa.InstrumentLogicalID
			,	PERCENTILE_DISC(0.5) Within Group (Order By DoubleResult) Over (Partition By pa.ParameterLogicalID) --Median
			,	StDev(DoubleResult) Over (Partition By pa.ParameterLogicalID)
			,	Count(sa.SampleID) Over (Partition By pa.ParameterLogicalID)

	From		tblMfCdSample sa
	Inner Join	tblMfCdSubSample su
		On		sa.SampleID = su.SampleID
	Inner Join	tblMfCdPredictedValue pv
		on		pv.SubSampleID = su.SubSampleID
	Inner Join	tblMfCdParameter pa
		on		pa.ParameterLogicalID = pv.ParameterLogicalID
	Inner Join	tblMfCdPredictionModel pm
		on		pm.PredictionModelLogicalID = pa.PredictionModelLogicalID

	Where		pa.Obsolete = 0
		and		pm.Obsolete = 0
		and		pv.Type = 0
		and		sa.SampleType = 0
		and		su.ParentSubSampleID is NULL
		and		pm.PredictionModelTypeID = 133
		and		sa.SampleID In (72108,72109,72110,72111,72112,72113,72114,72115,72116,72117,72118,72119,72120,72121,72122,72123,72124,72125,72126,72127,72128,72129,72130,72131,72132,72133,72134,72135,72136,72137,72138,72139,72140,72141,72142,72143,72144,72145,72146,72147,72148,72149,72150,72151,72152,72153,72154,72155,72156,72157,72158,72159,72160,72161,72162,72163,72164,72165,72166,72167,72168,72169,72170,72171,72172,72173,72174,72175,72176,72177,72178,72179,72180,72181,72182,72183,72184,72185,72186,72187,72188,72189,72190,72191,72192,72193,72194,72195,72196,72197,72198,72199,72200,72201,72202,72203,72204,72205,72206,72207,72208,72209,72210,72211,72212,72213,72214,72215,72216,72217,72218,72219,72220,72221,72222,72223,72224,72225,72226,72227,72228,72229,72230,72231,72232,72233,72234,72235,72236,72237,72238,72239,72240,72241,72242,72243,72244,72245,72246,72247,72248,72249,72250,72251,72252,72253,72254,72255,72256,72257,72258,72259,72260,72261,72262,72263,72264,72265,72266,72267,72268,72269,72270,72271,72272,72273,72274,72275,72276,72277,72278,72279,72280,72281,72282,72283,72284,72285,72286,72287,72288,72289,72290,72291,72292,72293,72294,72295,72296,72297,72298,72299,72300,72301,72302,72303,72304,72305,72306,72307,72308,72309,72310,72311,72312,72313,72314,72315,72316,72317,72318,72319,72320,72321,72322,72323,72324,72325,72326,72327,72328,72329,72330,72331,72332,72333,72334,72335,72336,72337,72338,72339,72340,72341,72342,72343,72344,72345,72346,72347,72348,72349,72350,72351,72352,72353,72354,72355,72356,72357,72358,72359,72360,72361,72362,72363,72364,72365,72366,72367,72368,72369,72370,72371,72372,72373,72374,72375,72376,72377,72378,72379,72380,72381,72382,72383,72384,72385,72386,72387,72388,72389,72390,72391,72392,72393,72394,72395,72396,72397,72398,72399,72400,72401,72402,72403,72404,72405,72406,72407,72408,72409,72410,72411,72412,72413,72414,72415,72416,72417,72418,72419,72420,72421,72422,72423,72424,72425,72426,72427,72428,72429,72430,72431,72432,72433,72434,72435,72436,72437,72438,72439,72440,72441,72442,72443,72444,72445,72446,72447,72448,72449,72450,72451,72452,72453,72454,72455,72456,72457,72458,72459,72460,72461,72462,72463,72464,72465,72466,72467,72468,72469,72470,72471,72472,72473,72474,72475,72476,72477,72478,72479,72480,72481,72482,72483,72484,72485,72486,72487,72488,72489,72490,72491,72492,72493,72494,72495,72496,72497,72498,72499,72500,72501,72502,72503,72504,72505,72506,72507,72508,72509,72510,72511,72512,72513,72514,72515,72516,72517,72518,72519,72520,72521,72522,72523,72524,72525,72526,72527,72528,72529,72530,72531,72532,72533,72534,72535,72536,72537,72538,72539,72540,72541,72542,72543,72544,72545,72546,72547,72548,72549,72550,72551,72552,72553,72554,72555,72556,72557,72558,72559,72560,72561,72562,72563,72564,72565,72566,72567,72568,72569,72570,72571,72572,72573,72574,72575,72576,72577,72578,72579,72580,72581,72582,72583,72584,72585,72586,72587,72588,72589,72590,72591,72592,72593,72594,72595,72596,72597,72598,72599,72600,72601,72602,72603,72604,72605,72606,72607,72608,72609,72610,72611,72612,72613,72614,72615,72616,72617,72618,72619,72620,72621,72622,72623,72624,72625,72626,72627,72628,72629,72630,72631,72632,72633,72634,72635,72636,72637,72638,72639,72640,72641,72642,72643,72644,72645,72646,72647,72648,72649,72650,72651,72652,72653,72654,72655,72656,72657,72658,72659,72660,72661,72662,72663,72664,72665,72666,72667,72668,72669,72670,72671,72672,72673,72674,72675,72676,72677,72678,72679,72680,72681,72682,72683,72684,72685,72686,72687,72688,72689,72690,72691,72692,72693,72694,72695,72696,72697,72698,72699,72700,72701,72702,72703,72704,72705,72706,72707,72708,72709,72710,72711,72712,72713,72714,72715,72716,72717,72718,72719,72720,72721,72722,72723,72724,72725,72726,72727,72728,72729,72730,72731,72732,72733,72734,72735,72736,72737,72738,72739,72740,72741,72742,72743,72744,72745,72746,72747,72748,72749,72750,72751,72752,72753,72754,72755,72756,72757,72758,72759,72760,72761,72762,72763,72764,72765,72766,72767,72768,72769,72770,72771,72772,72773,72774,72775,72776,72777,72778,72779,72780,72781,72782,72783,72784,72785,72786,72787,72788,72789,72790,72791)

Select *
From
(
Select		AnalysisTime 
		,	ParameterName 
	--	,	ProductName
	--	,	ProductLogicalID
		,	Result 
	--	,	SampleID 
	--	,	v.ParameterLogicalID
	--	,	InstrumentLogicalID
	--	,	NumberOfDecimals
	--	,	Median
	--	,	StdDev
	---	,	Cnt
	--	,	GoodProductLimit
	--	,	Intercept
From		#Values v
Inner Join	#Settings s
	on		s.ParameterLogicalID = v.ParameterLogicalID
Where ProductLogicalID Is Null
) s
Pivot
( Max(Result)
For ParameterName In ("Ammonium Sulphate","Cyanuric Acid","Formaldehyde","Hydroxyproline","Maltodextrin","Maltose","Melamine","Sodium Bicarbonate","Sodium Carbonate","Sodium Citrate","Sodium Nitrate","Sorbitol","Added Sucrose","Sodium Chloride","AFI","Added Glucose")
) p

Drop Table #Settings
Drop Table #Values