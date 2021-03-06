/*****************************************************************************************************
******************************************************************************************************
**                                                                                                  **
**                                   SOUTH ASIA MICRO DATABASE                                      **
**                                                                                                  **
** COUNTRY	India
** COUNTRY ISO CODE	IND
** YEAR	2009
** SURVEY NAME	SOCIO-ECONOMIC SURVEY  SIXTY-SIXTH ROUND: JULY 2009 – JUNE 2010
*	HOUSEHOLD SCHEDULE 10 : EMPLOYMENT AND UNEMPLOYMENT
** SURVEY AGENCY	GOVERNMENT OF INDIA NATIONAL SAMPLE SURVEY ORGANISATION
** CREATED  BY Triana Yentzen
** MODIFIED BY Fernando Enrique Morales Velandia
** Modified	 02/15/2018  
**                                                                                                  **
******************************************************************************************************
*****************************************************************************************************/

/*****************************************************************************************************
*                                                                                                    *
                                   INITIAL COMMANDS
*                                                                                                    *
*****************************************************************************************************/


** INITIAL COMMANDS
	cap log close
	clear
	set more off
	set mem 700m

** DIRECTORY
	local input "D:\SOUTH ASIA MICRO DATABASE\SAR_DATABANK\IND\IND_2009_NSS66-SCH1.0-T1\IND_2009_NSS66-SCH1.0-T1_v01_M"
	local output "D:\SOUTH ASIA MICRO DATABASE\SAR_DATABANK\IND\IND_2009_NSS66-SCH1.0-T1\IND_2009_NSS66-SCH1.0-T1_v01_M_v04_A_SARMD"
   	glo pricedata "D:\SOUTH ASIA MICRO DATABASE\CPI\cpi_ppp_sarmd_weighted.dta"
	glo shares "D:\SOUTH ASIA MICRO DATABASE\APPS\DATA CHECK\Food and non-food shares\IND"
	glo fixlabels "D:\SOUTH ASIA MICRO DATABASE\APPS\DATA CHECK\Label fixing"


** LOG FILE
	log using "`output'\Doc\Technical\IND_2009_NSS66-SCH1.0-T1_v01_M_v04_A_SARMD.log",replace


/*****************************************************************************************************
*                                                                                                    *
                                   * ASSEMBLE DATABASE
*                                                                                                    *
*****************************************************************************************************/

** DATABASE ASSEMBLENT

	* PREPARE DATASETS
	
	use "`input'\Data\Stata\NSS66_Sch1_Type1_bk_4.dta"
	sort hhid S1B4_v01
	format hhid %9.0f
	tempfile roster
	save `roster'

	use "`input'\Data\Stata\NSS66_Sch1_Type1_bk_1_2.dta"
	sort hhid
	format hhid %9.0f
	tempfile survey
	save `survey'
	
	use "`input'\Data\Stata\NSS66_Sch1_Type1_bk_3a.dta"
	sort hhid
	format hhid %9.0f
	tempfile household1
	save `household1'

	use "`input'\Data\Stata\NSS66_Sch1_Type1_bk_3b.dta"
	sort hhid
	format hhid %9.0f
	tempfile household2
	save `household2'
	
	
	*Assets
	use "`input'\Data\Stata\NSS66_Sch1_Type1_bk_11.dta"
	sort hhid 
	
	keep if inlist(S1B11_v02, 560, 561, 580, 582, 583, 584, 587, 600, 601, 602, 622, 623, 624)
	keep hhid S1B11_v02 S1B11_v03
	reshape wide S1B11_v03, i(hhid) j(S1B11_v02)
	tempfile assets
	save `assets'
	
	
	use "`input'\Data\Stata\poverty66.dta", clear

	keep hhid sector district hhsize mpce_mrp mpce_urp pline poor pwt pline_ind_09

	su pline_ind_09 [w=pwt]
	gen pline_mrp=r(mean)

	gen mpce_mrp_real=mpce_mrp*pline_mrp/pline

	sort hhid

	format hhid %9.0f

*	gen pline_urp_sector=.
*	replace pline_urp_sector=641.4 if sector==1
*	replace pline_urp_sector=931.2 if sector==2

	su pline [w=pwt]
	gen pline_urp=r(mean)

	gen mpce_urp_real=mpce_urp*(pline_urp/pline)
	la var mpce_urp_real "Real PC Monthly Consumption (URP)"
	ren pline_ind_09 pline_mrp_sector

	keep hhid mpce_urp_real mpce_mrp_real mpce_mrp pline_urp pline_mrp pline_mrp_sector pline pwt

	order hhid mpce_urp_real mpce_mrp_real mpce_mrp pline_urp pline_mrp pline_mrp_sector pline pwt

	* MERGE DATASETS
	
	merge 1:1 hhid using `survey'
	drop _merge
	
	merge 1:1 hhid using `household1'
	drop _merge
		
	merge 1:1 hhid using `household2'
	drop _merge
	
	merge 1:1 hhid using `assets'
	drop _merge
	
	merge 1:m hhid using `roster'

	
/*****************************************************************************************************
*                                                                                                    *
                                   HOUSEHOLD CHARACTERISTICS MODULE
*                                                                                                    *
*****************************************************************************************************/

	
** COUNTRY
*<_countrycode_>
	gen str4 countrycode="IND"
	label var countrycode "Country code"
*</_countrycode_>

	
** YEAR
*<_year_>
	gen int year=2009
	label var year "Year of survey"
*</_year_>


** SURVEY NAME 
*<_survey_>
	gen str survey="NSS-SCH1"
	label var survey "Survey Acronym"
*</_survey_>


	
** INTERVIEW YEAR
*<_int_year_>
	gen byte int_year=.
	replace S1B2_v02c=2009 if S1B2_v02c==9
	replace S1B2_v02c=2010 if S1B2_v02c==10
	replace int_year=S1B2_v02c
	label var int_year "Year of the interview"
*</_int_year_>
	
	
** INTERVIEW MONTH
*<_int_month_>
	gen byte int_month=S1B2_v02b
	la de lblint_month 1 "January" 2 "February" 3 "March" 4 "April" 5 "May" 6 "June" 7 "July" 8 "August" 9 "September" 10 "October" 11 "November" 12 "December"
	label value int_month lblint_month
	label var int_month "Month of the interview"
*</_int_month_>
	
	
	**FIELD WORKD***
*<_fieldwork_> 
gen fieldwork=ym(int_year, int_month)
format %tm fieldwork
la var fieldwork "Date of fieldwork"
*<_/fieldwork_> 

	
** HOUSEHOLD IDENTIFICATION NUMBER
*<_idh_>
	tostring hhid, gen(idh)
	label var idh "Household id"
*</_idh_>


	
** INDIVIDUAL IDENTIFICATION NUMBER
*<_idp_>
	egen idp=concat(idh S1B4_v01), punct(-)	
	label var idp "Individual id"
*</_idp_>
	isid idp


** HOUSEHOLD WEIGHTS
*<_wgt_>
	gen wgt=hhwt
	label var wgt "Household sampling weight"
*</_wgt_>


** STRATA
*<_strata_>
	gen strata=S1B1_v08
	label var strata "Strata"
*</_strata_>


** PSU
*<_psu_>
	gen psu=LOT_FSU
	destring psu , replace
	label var psu "Primary sampling units"
*</_psu_>

	
** MASTER VERSION
*<_vermast_>

	gen vermast="01"
	label var vermast "Master Version"
*</_vermast_>
	
	
** ALTERATION VERSION
*<_veralt_>

	gen veralt="04"
	label var veralt "Alteration Version"
*</_veralt_>	
	
/*****************************************************************************************************
*                                                                                                    *
                                   HOUSEHOLD CHARACTERISTICS MODULE
*                                                                                                    *
*****************************************************************************************************/


** LOCATION (URBAN/RURAL)
*<_urban_>
	gen urban=.
	replace urban=1 if S1B1_v05==2
	replace urban=0 if S1B1_v05==1
	label var urban "Urban/Rural"
	la de lblurban 1 "Urban" 0 "Rural"
	label values urban lblurban
*</_urban_>


/*** REGIONAL AREA 1 DIGIT ADMN LEVEL
*<_subnatid1_>
	recode state (1 2 3 4 6 8 = 1) (5 7 9 10 23 = 2) (12/18 = 3) (11 19 20 21 22 35 = 4) ( 24 25 26 27 30 = 5) (28 29 31 32 33 34 = 6), gen(subnatid1)
	label define lblsubnatid1 1 "Northern" 2 "North-Central" 3 "North-Eastern" 4 "Eastern" 5 "Western" 6 "Southern"*/
	gen subnatid2=.
	label var subnatid2 "Region at 2 digit (ADMN2)"
	label values subnatid2 lblsubnatid2
*</_subnatid1_>


** REGIONAL AREA 1 DIGIT ADMN LEVEL
*<_subnatid2_>
	gen subnatid1=state
	label define lblsubnatid1 1 "Jammu & Kashmir" 2 "Himachal Pradesh" 3 "Punjab" 4 "Chandigarh"            ///
	5 "Uttaranchal" 6 "Haryana" 7 "Delhi" 8 "Rajasthan" 9 "Uttar Pradesh" 10 "Bihar" 11 "Sikkim"            /// 
	12 "Arunachal Pradesh" 13 "Nagaland" 14 "Manipur" 15 "Mizoram" 16 "Tripura" 17 "Meghalaya"              ///
	18 "Assam" 19 "West Bengal" 20"Jharkhand" 21 "Orissa" 22"Chhattisgarh" 23 "Madhya Pradesh"              ///
	24 "Gujarat" 25 "Daman & Diu" 26 "Dadra & Nagar Haveli" 27 "Maharashtra" 28 "Andhra Pradesh"           ///
	29"Karnataka" 30 "Goa" 31"Lakshadweep" 32 "Kerala" 33 "Tamil Nadu" 34 "Pondicherry" 35 "A & N Islands"         
	label values subnatid1 lblsubnatid1
	label var subnatid1 "Region at 1 digit (ADMN1)"	
*</_subnatid2_>


** REGIONAL AREA 3 DIGIT ADMN LEVEL
*<_subnatid3_>
	gen byte subnatid3=.
	label var subnatid3 "Region at 3 digit (ADMN3)"
	label values subnatid3 lblsubnatid3
*</_subnatid3_>
	

** HOUSE OWNERSHIP
*<_ownhouse_>
	gen ownhouse=1 if S1B3_v18==1
	replace ownhouse=0 if !inlist(S1B3_v18, 1, .)
	label var ownhouse "House ownership"
	la de lblownhouse 0 "No" 1 "Yes"
	label values ownhouse lblownhouse
*</_ownhouse_>

** TENURE OF DWELLING
*<_tenure_>
   gen tenure=.
   replace tenure=1 if S1B3_v18==1
   replace tenure=2 if S1B3_v18==2 
   replace tenure=3 if S1B3_v18==3 | S1B3_v18==9
   label var tenure "Tenure of Dwelling"
   la de lbltenure 1 "Owner" 2"Renter" 3"Other"
   la val tenure lbltenure
*</_tenure_>


** LANDHOLDING
*<_landholding_>
   gen landholding=1 if S1B3_v07==1
   replace landholding=0 if S1B3_v07==2
   label var landholding "Household owns any land"
   la de lbllandholding 0 "No" 1 "Yes"
   la val landholding lbllandholding
*</_landholding_>	

** WATER PUBLIC CONNECTION
*<_water_>

	gen water=.
	label var water "Water main source"
	la de lblwater 0 "No" 1 "Yes"
	label values water lblwater
*</_water_>

	*ORIGINAL WATER CATEGORIES
	*<_water_original_>
	gen water_original=""
	la var water_original "Source of Drinking Water-Original from raw file"
	*</_water_original_>


	** WATER SOURCE
	*<_water_source_>
		gen water_source=.
		#delimit
			la de lblwater_source 1 "Piped water into dwelling" 	
								  2 "Piped water to yard/plot" 
								  3 "Public tap or standpipe" 
								  4 "Tubewell or borehole" 
								  5 "Protected dug well"
								  6 "Protected spring"
								  7 "Bottled water"
								  8 "Rainwater"
								  9 "Unprotected spring"
								  10 "Unprotected dug well"
								  11 "Cart with small tank/drum"
								  12 "Tanker-truck"
								  13 "Surface water"
								  14 "Other";
		#delimit cr
		la val water_source lblwater_source
		la var water_source "Sources of drinking water"
	*</_water_source_>

	
	** SAR IMPROVED SOURCE OF DRINKING WATER
	*<_improved_water_>
		gen improved_water=.
		la def lblimproved_water 1 "Improved" 0 "Unimproved"
		la val improved_water lblimproved_water
		la var improved_water "Improved access to drinking water"
	*</_improved_water_>



	** PIPED SOURCE OF WATER ACCESS
	*<_pipedwater_acc_>
		gen pipedwater_acc=.
		#delimit 
		la def lblpipedwater_acc	0 "No"
									1 "Yes, in premise"
									2 "Yes, but not in premise"
									3 "Yes, unstated whether in or outside premise";
		#delimit cr
		la val pipedwater_acc lblpipedwater_acc
		la var pipedwater_acc "Household has access to piped water"
	*</_pipedwater_acc_>

		** WATER TYPE VARIABLE USED IN THE SURVEY
	*<_watertype_quest_>
		gen watertype_quest=.
		#delimit
		la def lblwaterquest_type	1 "Drinking water"
									2 "General water"
									3 "Both"
									4 "Others";
		#delimit cr
		la val watertype_quest lblwaterquest_type
		la var watertype_quest "Type of water questions used in the survey"
	*</_watertype_quest_>
	
	
** ELECTRICITY PUBLIC CONNECTION
*<_electricity_>
	gen electricity=S1B3_v17
	recode electricity (5=1) (1 2 3 4 6 9=0)	
	label var electricity "Electricity main source"
	la de lblelectricity 0 "No" 1 "Yes"
	label values electricity lblelectricity
*</_electricity_>

** TOILET PUBLIC CONNECTION
*<_toilet_>

	gen toilet=.
	label var toilet "Toilet facility"
	la de lbltoilet 0 "No" 1 "Yes"
	label values toilet lbltoilet
*</_toilet_>


	** ORIGINAL SANITATION CATEGORIES 
	*<_sanitation_original_>
		gen sanitation_original="" 
		la var sanitation_original "Access to sanitation facility-Original from raw file"
	*</_sanitation_original_>


	** SANITATION SOURCE
	*<_sanitation_source_>
		gen sanitation_source=.
		#delimit
		la def lblsanitation_source	1	"A flush toilet"
									2	"A piped sewer system"
									3	"A septic tank"
									4	"Pit latrine"
									5	"Ventilated improved pit latrine (VIP)"
									6	"Pit latrine with slab"
									7	"Composting toilet"
									8	"Special case"
									9	"A flush/pour flush to elsewhere"
									10	"A pit latrine without slab"
									11	"Bucket"
									12	"Hanging toilet or hanging latrine"
									13	"No facilities or bush or field"
									14	"Other";
		#delimit cr
		la val sanitation_source lblsanitation_source
		la var sanitation_source "Sources of sanitation facilities"
	*</_sanitation_source_>

	
	** SAR IMPROVED SANITATION 
	*<_improved_sanitation_>
		gen improved_sanitation=.
		la def lblimproved_sanitation 1 "Improved" 0 "Unimproved"
		la val improved_sanitation lblimproved_sanitation
		la var improved_sanitation "Improved type of sanitation facility-using country-specific definitions"
	*</_improved_sanitation_>
	

	** ACCESS TO FLUSH TOILET
	*<_toilet_acc_>
		gen toilet_acc=.
		#delimit 
		la def lbltoilet_acc		0 "No"
									1 "Yes, in premise"
									2 "Yes, but not in premise"
									3 "Yes, unstated whether in or outside premise";
		#delimit cr
		la val toilet_acc lbltoilet_acc
		la var toilet_acc "Household has access to flushed toilet"
	*</_toilet_acc_>

	
** INTERNET
	recode S1B3_v22 (2=0), gen(internet)
	label var internet "Internet connection"
	la de lblinternet 0 "No" 1 "Yes"
	label values internet lblinternet


/*****************************************************************************************************
*                                                                                                    *
                                   DEMOGRAPHIC MODULE
*                                                                                                    *
*****************************************************************************************************/
	
	
**HOUSEHOLD SIZE
	gen hsize=S1B3_v01
	la var hsize "Household size"
*</_hsize_>
	
**POPULATION WEIGHT
*<_pop_wgt_>
	gen pop_wgt=wgt*hsize
	la var pop_wgt "Population weight"
*</_pop_wgt_>

** HOUSEHOLD WEIGHTS FOR THE WDI
*<_wgt_wdi_>

egen wgt_urban=total(wgt) if urban==1
egen wgt_rural=total(wgt) if urban==0

gen wgt_wdi=wgt*(376075566.5/wgt_urban) if urban==1
replace wgt_wdi=wgt*(846549845/wgt_rural) if urban==0
label var wgt_wdi "Household sampling weight using WDI population growth"
*</_wgt_wdi_>
	
** RELATIONSHIP TO THE HEAD OF HOUSEHOLD
*<_relationharm_>
	gen relationharm= S1B4_v03
	recode relationharm (3 5 = 3) (7=4) (4 6 8 = 5) (9=6)
	label var relationharm "Relationship to the head of household"
	la de lblrelationharm  1 "Head of household" 2 "Spouse" 3 "Children" 4 "Parents" 5 "Other relatives" 6 "Non-relatives"
	label values relationharm  lblrelationharm
*</_relationharm_>

** RELATIONSHIP TO THE HEAD OF HOUSEHOLD
*<_relationcs_>

	gen byte relationcs=S1B4_v03
	la var relationcs "Relationship to the head of household country/region specific"
	label define lblrelationcs 1 "Head" 2 "Spouse of head" 3 "married child" 4 "spouse of married child" 5 "unmarried child" 6 "grandchild" 7 "father/mother/father-in-law/mother-in-law" 8 "brother/sister/brother-in-law/sister-in-law/other relations" 9 "servant/employee/other non-relative"
	label values relationcs lblrelationcs
*</_relationcs_>


** GENDER
*<_male_>
	gen male=S1B4_v04
	recode male (2=0)
	label var male "Sex of household member"
	la de lblmale 1 "Male" 0 "Female"
	label values male lblmale
*</_male_>



** AGE
*<_age_>
	gen age=S1B4_v05
	replace age=98 if age>98 & age<.
	label var age "Age of individual"
*</_age_>

** SOCIAL GROUP
*<_soc_>

/*
Caste variable exist too, named "S1B3_v06"
*/
	gen soc=S1B3_v05
	label var soc "Social group"
	label define lblsoc 1 "Hinduism" 2 "Islam" 3 "Christianity" 4 "Sikhism" 5 "Jainism" 6 "Buddhism" 7 "Zoroastrianism" 9 "Others"
	label values soc lblsoc
*</_soc_>


** MARITAL STATUS
*<_marital_>
gen marital=S1B4_v06
	recode marital (1=2) (2=1) (3=5)
	label var marital "Marital status"
	la de lblmarital 1 "Married" 2 "Never Married" 3 "Living Together" 4 "Divorced/separated" 5 "Widowed"
	label values marital lblmarital
*</_marital_>


/*****************************************************************************************************
*                                                                                                    *
                                   EDUCATION MODULE
*                                                                                                    *
*****************************************************************************************************/


** EDUCATION MODULE AGE
*<_ed_mod_age_>
	gen ed_mod_age=0
	label var ed_mod_age "Education module application age"
*</_ed_mod_age_>


** CURRENTLY AT SCHOOL
*<_atschool_>
	gen atschool=.
	label var atschool "Attending school"
	la de lblatschool 0 "No" 1 "Yes"
	label values atschool  lblatschool
*</_atschool_>

	** CAN READ AND WRITE
*<_literacy_>
	gen literacy=S1B4_v07
	recode literacy (1= 0)(2/13=1) 
	label var literacy "Can read & write"
	la de lblliteracy 0 "No" 1 "Yes"
	label values literacy lblliteracy
*</_literacy_>


** YEARS OF EDUCATION COMPLETED
*<_educy_>
	gen educy=S1B4_v07
	recode educy ( 1/4= 0) (5=2)(6=5) (7=8) (8 10 =10) (11=12) (12=15) (13=17)
	label var educy "Years of education"
	replace educy=. if educy>age & educy!=. & age!=.
*</_educy_>


** EDUCATION LEVEL 7 CATEGORIES
*<_educat7_>
	gen educat7=.
	replace educat7=1 if S1B4_v07==1 | S1B4_v07==2 |S1B4_v07==3 | S1B4_v07==4
	replace educat7=2 if S1B4_v07==5
	replace educat7=3 if S1B4_v07==6
	replace educat7=4 if S1B4_v07==7 | S1B4_v07==8
	replace educat7=5 if S1B4_v07==10
	replace educat7=6 if S1B4_v07==11
	replace educat7=7 if S1B4_v07>11 & S1B4_v07!=.
	label define lbleducat7 1 "No education" 2 "Primary incomplete" 3 "Primary complete" ///
	4 "Secondary incomplete" 5 "Secondary complete" 6 "Higher than secondary but not university" /// 
	7 "University incomplete or complete" 8 "Other" 9 "Not classified"
	label values educat7 lbleducat7 
	la var educat7 "Level of education 7 categories"


** EDUCATION LEVEL 5 CATEGORIES
*<_educat5_>
	gen educat5=.
	replace educat5=1 if educat7==1
	replace educat5=2 if educat7==2
	replace educat5=3 if educat7==3 | educat7==4
	replace educat5=4 if educat7==5
	replace educat5=5 if educat7==6 | educat7==7
	label define lbleducat5 1 "No education" 2 "Primary incomplete" ///
	3 "Primary complete but secondary incomplete" 4 "Secondary complete" ///
	5 "Some tertiary/post-secondary"
	label values educat5 lbleducat5
*</_educat5_>

	la var educat5 "Level of education 5 categories"


** EDUCATION LEVEL 4 CATEGORIES
*<_educat4_>
	gen educat4=.
	replace educat4=1 if educat7==1
	replace educat4=2 if educat7==2 | educat7==3
	replace educat4=3 if educat7==4 | educat7==5
	replace educat4=4 if educat7==6 | educat7==7
	label var educat4 "Level of education 4 categories"
	label define lbleducat4 1 "No education" 2 "Primary (complete or incomplete)" ///
	3 "Secondary (complete or incomplete)" 4 "Tertiary (complete or incomplete)"
	label values educat4 lbleducat4
*</_educat4_>
	

** EVER ATTENDED SCHOOL
*<_everattend_>
	recode S1B4_v07 (1 2 3 4 = 0) (5 6 7 8 10 11 12 13=1), gen (everattend)
	label var everattend "Ever attended school"
	la de lbleverattend 0 "No" 1 "Yes"
	label values everattend lbleverattend
*</_everattend_>



/*****************************************************************************************************
*                                                                                                    *
                                   LABOR MODULE
*                                                                                                    *
*****************************************************************************************************/


** LABOR MODULE AGE
*<_lb_mod_age_>

	gen lb_mod_age=.
	label var lb_mod_age "Labor module application age"
*</_lb_mod_age_>


** LABOR STATUS
*<_lstatus_>
	gen lstatus=.
	label var lstatus "Labor status"
	la de lbllstatus 1 "Employed" 2 "Unemployed" 3 "Non-LF"
	label values lstatus lbllstatus
*</_lstatus_>
	replace lstatus=. if  age<lb_mod_age


** EMPLOYMENT STATUS
*<_empstat_>
	gen empstat=.
	label var empstat "Employment status"
	la de lblempstat 1 "Paid employee" 2 "Non-paid employee" 3 "Employer" 4 "Self-employed"
	label values empstat lblempstat
*</_empstat_>


** SECTOR OF ACTIVITY: PUBLIC - PRIVATE
*<_njobs_>
	gen njobs=.
	label var njobs "Number of additional jobs"
*</_njobs_>


** SECTOR OF ACTIVITY: PUBLIC - PRIVATE
*<_ocusec_>
	gen ocusec=.
	label var ocusec "Sector of activity"
	la de lblocusec 1 "Public, state owned, government, army" 2 "NGO" 3 "Private"
	label values ocusec lblocusec
*</_ocusec_>
	replace ocusec=. if lstatus!=1


** REASONS NOT IN THE LABOR FORCE
*<_nlfreason_>
	gen nlfreason=.
	label var nlfreason "Reason not in the labor force"
	la de lblnlfreason 1 "Student" 2 "Housewife" 3 "Retired" 4 "Disable" 5 "Other"
	label values nlfreason lblnlfreason
*</_nlfreason_>

** UNEMPLOYMENT DURATION: MONTHS LOOKING FOR A JOB
*<_unempldur_l_>
	gen unempldur_l=.
	label var unempldur_l "Unemployment duration (months) lower bracket"
*</_unempldur_l_>

*<_unempldur_u_>

	gen unempldur_u=.
	label var unempldur_u "Unemployment duration (months) upper bracket"
*</_unempldur_u_>


** INDUSTRY CLASSIFICATION
*<_industry_>
	gen industry=.
	label var industry "1 digit industry classification"
	la de lblindustry 1 "Agriculture" 2 "Mining" 3 "Manufacturing" 4 "Public utilities" 5 "Construction"  6 "Commerce" 7 "Transports and comnunications" 8 "Financial and business-oriented services" 9 "Community and family oriented services" 10 "Others"
	label values industry lblindustry
*</_industry_>



** OCCUPATION CLASSIFICATION
*<_occup_>
	gen occup=.
	label var occup "1 digit occupational classification"
	label define lbloccup 1 "Senior officials" 2 "Professionals" 3 "Technicians" 4 "Clerks" ///
	5 "Service and market sales workers" 6 "Skilled agricultural" 7 "Craft workers" ///
	8 "Machine operators" 9 "Elementary occupations" 10 "Armed forces"  99 "Others"
	label values occup lbloccup
*</_occup_>


** FIRM SIZE
*<_firmsize_l_>
	gen firmsize_l=.
	label var firmsize_l "Firm size (lower bracket)"
*</_firmsize_l_>

*<_firmsize_u_>

	gen firmsize_u=.
	label var firmsize_u "Firm size (upper bracket)"

*</_firmsize_u_>


** HOURS WORKED LAST WEEK

*<_whours_>
	gen whours=.
	label var whours "Hours of work in last week"
*</_whours_>


** WAGES
*<_wage_>
	gen wage=.
	label var wage "Last wage payment"
*</_wage_>

** WAGES TIME UNIT
*<_unitwage_>

	gen unitwage=.
	label var unitwage "Last wages time unit"
	la de lblunitwage 1 "Daily" 2 "Weekly" 3 "Every two weeks" 4 "Bimonthly"  5 "Monthly" 6 "Trimester" 7 "Biannual" 8 "Annually" 9 "Hourly" 
	label values unitwage lblunitwage
*</_wageunit_>


** CONTRACT
*<_contract_>
	gen contract=.
	label var contract "Contract"
	la de lblcontract 0 "Without contract" 1 "With contract"
	label values contract lblcontract
*</_contract_>


	gen healthins=.

** HEALTH INSURANCE
*<_healthins_>
	label var healthins "Health insurance"
	la de lblhealthins 0 "Without health insurance" 1 "With health insurance"
	label values healthins lblhealthins
*</_healthins_>

	gen socialsec=.

** SOCIAL SECURITY
*<_socialsec_>
	label var socialsec "Social security"
	la de lblsocialsec 1 "With" 0 "Without"
	label values socialsec lblsocialsec
*</_socialsec_>

	gen union=.

** UNION MEMBERSHIP
*<_union_>
	la de lblunion 0 "No member" 1 "Member"
	label var union "Union membership"
	label values union lblunion
*</_union_>

	local lb_var "lstatus empstat njobs ocusec nlfreason unempldur_l unempldur_u industry occup firmsize_l firmsize_u whours wage unitwage contract healthins socialsec union"
	foreach v in `lb_var'{
	di "check `v' only for age>=lb_mod_age"

	replace `v'=. if( age<lb_mod_age & age!=.)
	}
	label var occup "1 digit occupational classification"
	label define occup 1 "Senior officials" 2 "Professionals" 3 "Technicians" 4 "Clerks" ///
	5 "Service and market sales workers" 6 "Skilled agricultural" 7 "Craft workers" ///
	8 "Machine operators" 9 "Elementary occupations" 10 "Armed forces"  99 "Others"
	label values occup occup
	replace occup=. if lstatus!=1
	
/*****************************************************************************************************
*                                                                                                    *
                                   LABOR MODULE FOR INDIA
*                                                                                                    *
*****************************************************************************************************/

* main income earner OF THE HOUSEHOLD (_e)

** LABOR STATUS
*<_lstatus_e_>
	gen lstatus_e=.
	label var lstatus_e "Labor status (main earner)"
	la de lbllstatus_e 1 "Employed" 2 "Unemployed" 3 "Non-LF"
	label values lstatus_e lbllstatus_e
*</_lstatus_e_>


** EMPLOYMENT STATUS MAIN EARNER
*<_empstat_e_>
	gen empstat_e=.
	replace empstat_e=1 if S1B3_v04==2
	replace empstat_e=4 if S1B3_v04==1 | S1B3_v04==4
	replace empstat_e=5 if S1B3_v04==3 | S1B3_v04==9
	label var empstat_e "Employment status (main earner)"
	la de lblempstat_e 1 "Paid employee" 2 "Non-paid employee" 3 "Employer" 4 "Self-employed" 5 "Other"
	label values empstat_e lblempstat_e
*</_empstat_e_>

**ORIGINAL INDUSTRY CLASSIFICATION
*<_industry_e_orig_>
    gen ind1=S1B3_v02
	replace ind1= "99" if strpos( ind1 , "x")
	destring ind1, replace
	ren ind1 industry_e_orig
	la var industry_e_orig "Original industry code"

*</_industry_e_orig_>

** INDUSTRY CLASSIFICATION MAIN EARNER
*<_industry_e_>
    gen ind=substr(S1B3_v02,1,3)
	replace ind="99" if inlist(ind,"05x","20x","23x","25x","26x","29x","30x") 
	replace ind="99" if inlist(ind,"36x","52x","55x","65x","75x", "80x","92x","95x") 
	destring ind, replace
	recode ind 	(11/50=1) (101/142=2) (151/372=3) (401/410=4) (451/455=5) (501/552=6) ///
	(601/642=7) (651/749=8) (751/753=9) (801/990 99 =10), gen(industry_e)
	label var industry_e "1 digit industry classification (main earner)"
	la de lblindustry_e 1 "Agriculture" 2 "Mining" 3 "Manufacturing" 4 "Public utilities"  ///
	5 "Construction"  6 "Commerce" 7 "Transports and comnunications" ///
	8 "Financial and business-oriented services" 9 "Public Administration" 10 "Other services, Unspecified"
	label values industry_e lblindustry_e

**ORIGINAL OCCUPATION CLASSIFICATION
*<_occup_e_orig_>
	replace S1B3_v03="0" if inlist(S1B3_v03,"01x","02x","05x","11x","13x","15x","16x","19x") 
	replace S1B3_v03="0" if inlist(S1B3_v03,"21x","25x","29x","32x","33x","35x","37x","40x") 
	replace S1B3_v03="0" if inlist(S1B3_v03,"41x","51x","52x","55x","61x", "62x","63x","64x") 
	replace S1B3_v03="0" if inlist(S1B3_v03,"71x","72x","91x","92x","93x", "95x","X00","X10","X99") 
	gen ocup1=S1B3_v03 
	replace ocup1="99" if ocup=="0"
	destring ocup1, replace
	gen occup_e_orig=ocup1
	replace occup_e_orig="99" if strpos( occup_e_orig, "x")
	destring occup_e_orig, replace
	drop ocup1
	la var occup_e_orig "Original occupation code"
	notes occup_e_orig: "IND 2009" Subset of variable was kept to avoid strange characters
*</_occup_e_orig_>


** OCCUPATION CLASSIFICATION MAIN EARNER
*<_occup_e_>

	replace S1B3_v03="0" if inlist(S1B3_v03,"01x","02x","05x","11x","13x","15x","16x","19x") 
	replace S1B3_v03="0" if inlist(S1B3_v03,"21x","25x","29x","32x","33x","35x","37x","40x") 
	replace S1B3_v03="0" if inlist(S1B3_v03,"41x","51x","52x","55x","61x", "62x","63x","64x") 
	replace S1B3_v03="0" if inlist(S1B3_v03,"71x","72x","91x","92x","93x", "95x","X00","X10","X99") 
	
	gen ocup=substr(S1B3_v03,1,1) 
	replace ocup="99" if ocup=="0"
	destring ocup, replace
	gen occup_e=ocup
	label var occup_e "1 digit occupational classification (main earner)"
	label define occup_e 1 "Senior officials" 2 "Professionals" 3 "Technicians" 4 "Clerks" ///
	5 "Service and market sales workers" 6 "Skilled agricultural" 7 "Craft workers" ///
	8 "Machine operators" 9 "Elementary occupations" 10 "Armed forces"  99 "Others"
	label values occup_e occup_e
*</_occup_e_>

	note lstatus_e: "INDIA 2009"	Data recolected only for main income earner of the household.
	note empstat_e: "INDIA 2009"	Data recolected only for main income earner of the household.
	note industry_e: "INDIA 2009"	Data recolected only for main income earner of the household.
	note occup_e: 	"INDIA 2009"	Data recolected only for main income earner of the household.
	note _dta: "IND 2009" No information on second occupations for this survey.

	
/*****************************************************************************************************
*                                                                                                    *
                                            ASSETS 
*                                                                                                    *
*****************************************************************************************************/
	
** LAND PHONE
*<_landphone_>
    gen landphone=1 if S1B11_v03624==1
	replace landphone=0 if S1B11_v03624==2
	label var landphone "Phone availability"
	la de lbllandphone 0 "No" 1 "Yes"
	label values landphone lbllandphone
*</_landphone_>


** CEL PHONE
*<_cellphone_>
	gen cellphone=1 if S1B11_v03623==1
	replace cellphone=0 if S1B11_v03623==2
	label var cellphone "Household has a cell phone"
	la de lblcellphone 0 "No" 1 "Yes"
	label values cellphone lblcellphone
*</_cellphone_>


** COMPUTER
*<_computer_>
	gen computer=1 if S1B11_v03622==1
	replace computer=0 if S1B11_v03622==2
	label var computer "Household has a computer"
	la de lblcomputer 0 "No" 1 "Yes"
	label values computer lblcomputer
*</_computer_>

** RADIO
*<_radio_>
	gen radio=1 if S1B11_v03560==1
	replace radio=0 if S1B11_v03560==2
	label var radio "household has a radio"
	la de lblradio 0 "No" 1 "Yes"
	label val radio lblradio
*</_radio_>

** TELEVISION
*<_television_>
	gen television=1 if S1B11_v03561==1
	replace television=0 if S1B11_v03561==2
	label var television "Household has a television"
	la de lbltelevision 0 "No" 1 "Yes"
	label val television lbltelevision
*</_television>

** FAN
*<_fan_>
	gen fan=1 if S1B11_v03580==1
	replace fan=0 if S1B11_v03580==2
	label var fan "Household has a fan"
	la de lblfan 0 "No" 1 "Yes"
	label val fan lblfan
*</_fan>

** SEWING MACHINE
*<_sewingmachine_>
	gen sewingmachine=1 if S1B11_v03583==1
	replace sewingmachine=0 if S1B11_v03583==2
	label var sewingmachine "Household has a sewing machine"
	la de lblsewingmachine 0 "No" 1 "Yes"
	label val sewingmachine lblsewingmachine
*</_sewingmachine>

** WASHING MACHINE
*<_washingmachine_>
	gen washingmachine=1 if S1B11_v03584==1
	replace washingmachine=0 if S1B11_v03584==2
	label var washingmachine "Household has a washing machine"
	la de lblwashingmachine 0 "No" 1 "Yes"
	label val washingmachine lblwashingmachine
*</_washingmachine>

** REFRIGERATOR
*<_refrigerator_>
	gen refrigerator=1 if S1B11_v03587==1
	replace refrigerator=0 if S1B11_v03587==2
	label var refrigerator "Household has a refrigerator"
	la de lblrefrigerator 0 "No" 1 "Yes"
	label val refrigerator lblrefrigerator
*</_refrigerator>

** LAMP
*<_lamp_>
	gen lamp=1 if S1B11_v03582==1
	replace lamp=0 if S1B11_v03582==2
	label var lamp "Household has a lamp"
	la de lbllamp 0 "No" 1 "Yes"
	label val lamp lbllamp
*</_lamp>

** BYCICLE
*<_bycicle_>
	gen bicycle=1 if S1B11_v03600==1
	replace bicycle=0 if S1B11_v03600==2
	label var bicycle "Household has a bicycle"
	la de lblbycicle 0 "No" 1 "Yes"
	label val bicycle lblbycicle
*</_bycicle>

** MOTORCYCLE
*<_motorcycle_>
	gen motorcycle=1 if S1B11_v03601==1
	replace motorcycle=0 if S1B11_v03601==2
	label var motorcycle "Household has a motorcycle"
	la de lblmotorcycle 0 "No" 1 "Yes"
	label val motorcycle lblmotorcycle
*</_motorcycle>

** MOTOR CAR
*<_motorcar_>
	gen motorcar=1 if S1B11_v03602==1
	replace motorcar=0 if S1B11_v03602==2
	label var motorcar "household has a motor car"
	la de lblmotorcar 0 "No" 1 "Yes"
	label val motorcar lblmotorcar
*</_motorcar>

** COW
*<_cow_>
	gen cow=.
	label var cow "Household has a cow"
	la de lblcow 0 "No" 1 "Yes"
	label val cow lblcow
*</_cow>

** BUFFALO
*<_buffalo_>
	gen buffalo=.
	label var buffalo "Household has a buffalo"
	la de lblbuffalo 0 "No" 1 "Yes"
	label val buffalo lblbuffalo
*</_buffalo>

** CHICKEN
*<_chicken_>
	gen chicken=.
	label var chicken "Household has a chicken"
	la de lblchicken 0 "No" 1 "Yes"
	label val chicken lblchicken
*</_chicken>		
	
/*****************************************************************************************************
*                                                                                                    *
                                   WELFARE MODULE
*                                                                                                    *
*****************************************************************************************************/


** SPATIAL DEFLATOR
*<_spdef_>
	gen spdef=pline
	la var spdef "Spatial deflator"
*</_spdef_>

** WELFARE
*<_welfare_>
	gen welfare=MPCE_URP/100
	la var welfare "Welfare aggregate"
*</_welfare_>

*<_welfarenom_>
	gen welfarenom=MPCE_URP/100
	la var welfarenom "Welfare aggregate in nominal terms"
*</_welfarenom_>

*<_welfaredef_>
	gen welfaredef=mpce_urp_real
	la var welfaredef "Welfare aggregate spatially deflated"
*</_welfaredef_>

*<_welfshprosperity_>
	gen welfshprosperity=welfare
	la var welfshprosperity "Welfare aggregate for shared prosperity"
*</_welfshprosperity_>

*<_welfaretype_>
	gen welfaretype="EXP"
	la var welfaretype "Type of welfare measure (income, consumption or expenditure) for welfare, welfarenom, welfaredef"
*</_welfaretype_>

*<_welfareother_>
	gen welfareother=mpce_mrp
	la var welfareother "Welfare Aggregate if different welfare type is used from welfare, welfarenom, welfaredef"
*</_welfareother_>

*<_welfareothertype_>
	gen welfareothertype="EXP"
	la var welfareothertype "Type of welfare measure (income, consumption or expenditure) for welfareother"
*</_welfareothertype_>

*<_welfarenat_>
	gen welfarenat=mpce_mrp
	la var welfarenat "Welfare aggregate for national poverty"
*</_welfarenat_>


*QUINTILE, DECILE AND FOOD/NON-FOOD SHARES OF CONSUMPTION AGGREGATE
	levelsof year, loc(y)
	merge m:1 idh using "$shares\\IND_fnf_`y'", keepusing (food_share nfood_share quintile_cons_aggregate decile_cons_aggregate) gen(_merge2)
	drop _merge



/*****************************************************************************************************
*                                                                                                    *
                                   NATIONAL POVERTY
*                                                                                                    *
*****************************************************************************************************/


** POVERTY LINE (NATIONAL)
*<_pline_nat_>
	ren pline pline_nat
	label variable pline_nat "Poverty Line (National)"
*</_pline_nat_>


** HEADCOUNT RATIO (NATIONAL)
*<_poor_nat_>
	gen poor_nat=welfarenat<pline_nat & welfareother!=.
	la var poor_nat "People below Poverty Line (National)"
	la define poor_nat 0 "Not Poor" 1 "Poor"
	la values poor_nat poor_nat
*</_poor_nat_>


/*****************************************************************************************************
*                                                                                                    *
                                   INTERNATIONAL POVERTY
*                                                                                                    *
*****************************************************************************************************/


	local year=2011
	
** USE SARMD CPI AND PPP
*<_cpi_>
	capture drop _merge
	gen urb=urban
	merge m:1 countrycode year urb using "$pricedata", keepusing(countrycode year urb syear cpi`year'_w ppp`year')
	drop urb
	drop if _merge!=3
	drop _merge
	
	
** CPI VARIABLE
	ren cpi`year'_w cpi
	label variable cpi "CPI (Base `year'=1)"
*</_cpi_>
	
	
** PPP VARIABLE
*<_ppp_>
	ren ppp`year' 	ppp
	label variable ppp "PPP `year'"
*</_ppp_>

	
** CPI PERIOD
*<_cpiperiod_>
	gen cpiperiod=syear
	label var cpiperiod "Periodicity of CPI (year, year&month, year&quarter, weighted)"
*</_cpiperiod_>	

** POVERTY LINE (POVCALNET)
*<_pline_int_>
	gen pline_int=1.90*cpi*ppp*365/12
	label variable pline_int "Poverty Line (Povcalnet)"
*</_pline_int_>
	
	
** HEADCOUNT RATIO (POVCALNET)
*<_poor_int_>
	gen poor_int=welfare<pline_int & welfare!=.
	la var poor_int "People below Poverty Line (Povcalnet)"
	la define poor_int 0 "Not Poor" 1 "Poor"
	la values poor_int poor_int
*</_poor_int_>


/*****************************************************************************************************
*                                                                                                    *
                                   FINAL STEPS
*                                                                                                    *
*****************************************************************************************************/
** KEEP VARIABLES - ALL
	do "$fixlabels\fixlabels", nostop

	keep countrycode year survey idh idp wgt pop_wgt wgt_wdi strata psu vermast veralt urban int_month int_year fieldwork  ///
	     subnatid1 subnatid2 subnatid3 ownhouse landholding tenure water electricity toilet internet ///
		 hsize relationharm relationcs male age soc marital ed_mod_age everattend ///
		 water_original water_source improved_water pipedwater_acc watertype_quest sanitation_original sanitation_source improved_sanitation toilet_acc ///
	     atschool electricity literacy educy educat4 educat5 educat7 lb_mod_age lstatus empstat njobs ///
	     ocusec nlfreason unempldur_l unempldur_u industry  occup firmsize_l firmsize_u whours wage ///
		 unitwage contract healthins socialsec union lstatus_e empstat_e industry_e_orig industry_e occup_e_orig occup_e  ///
		 landphone cellphone computer radio television fan sewingmachine washingmachine  ///
		 refrigerator lamp bicycle motorcycle motorcar cow buffalo chicken  ///
		 pline_nat pline_int poor_nat poor_int spdef cpi ppp cpiperiod welfare welfshprosperity food_share nfood_share quintile_cons_aggregate decile_cons_aggregate welfarenom welfaredef ///
		 welfarenat welfareother welfaretype welfareothertype

** ORDER VARIABLES

	order countrycode year survey idh idp wgt pop_wgt wgt_wdi strata psu vermast veralt urban int_month int_year fieldwork  ///
	      subnatid1 subnatid2 subnatid3 ownhouse landholding tenure water water_original water_source improved_water pipedwater_acc ///
		  watertype_quest sanitation_original sanitation_source improved_sanitation toilet_acc electricity toilet internet ///
	      hsize relationharm relationcs male age soc marital ed_mod_age everattend ///
	      atschool electricity literacy educy educat4 educat5 educat7 lb_mod_age lstatus empstat njobs ///
	      ocusec nlfreason unempldur_l unempldur_u industry occup firmsize_l firmsize_u whours wage ///
		  unitwage contract healthins socialsec union lstatus_e empstat_e industry_e_orig industry_e  occup_e_orig occup_e  ///
		  landphone cellphone computer radio television fan sewingmachine washingmachine  ///
		  refrigerator lamp bicycle motorcycle motorcar cow buffalo chicken  ///
		  pline_nat pline_int poor_nat poor_int spdef cpi ppp cpiperiod welfare welfshprosperity food_share nfood_share quintile_cons_aggregate decile_cons_aggregate welfarenom welfaredef ///
		  welfarenat welfareother welfaretype welfareothertype
	
	compress

** DELETE MISSING VARIABLES

	glo keep=""
	qui levelsof countrycode, local(cty)
	foreach var of varlist countrycode - welfareothertype {
		capture assert mi(`var')
		if !_rc {
		
			 display as txt "Variable " as result "`var'" as txt " for countrycode " as result `cty' as txt " contains all missing values -" as error " Variable Deleted"
			 
		}
		else {
		
			 glo keep = "$keep"+" "+"`var'"
			 
		}
	}
		
	foreach w in welfare welfareother {
	
		qui su `w'
		if r(N)==0 {
		
		drop `w'type
		
		}
	}
	
	keep countrycode year survey idh idp wgt pop_wgt strata psu vermast veralt  ${keep} *type
    sort idh idp
	
	compress
	

	saveold "`output'\Data\Harmonized\IND_2009_NSS66-SCH1.0-T1_v01_M_v04_A_SARMD_IND.dta", replace version(12)
	saveold "D:\SOUTH ASIA MICRO DATABASE\SAR_DATABANK\__REGIONAL\Individual Files\IND_2009_NSS66-SCH1.0-T1_v01_M_v04_A_SARMD_IND.dta", replace version(12)
	
	
	log close



******************************  END OF DO-FILE  *****************************************************/
