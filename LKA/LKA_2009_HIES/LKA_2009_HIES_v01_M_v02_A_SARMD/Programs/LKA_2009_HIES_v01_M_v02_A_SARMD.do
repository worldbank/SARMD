/*****************************************************************************************************
******************************************************************************************************
**                                                                                                  **
**                                   SOUTH ASIA MICRO DATABASE                                      **
**                                                                                                  **
** COUNTRY			Sri Lanka
** COUNTRY ISO CODE	LKA
** YEAR				2009
** SURVEY NAME		HOUSEHOLD INCOME AND EXPENDITURE SURVEY - 2009/10
** SURVEY AGENCY	NATIONAL HOUSEHOLD SAMPLE SURVEY PROGRAMME
** RESPONSIBLE		Triana Yentzen
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
	set mem 800m


** DIRECTORY
	local input "D:\SOUTH ASIA MICRO DATABASE\SAR_DATABANK\LKA\LKA_2009_HIES\LKA_2009_HIES_v01_M"
	local output "D:\SOUTH ASIA MICRO DATABASE\SAR_DATABANK\LKA\LKA_2009_HIES\LKA_2009_HIES_v01_M_v02_A_SARMD\"

** LOG FILE
	log using "`output'\Doc\Technical\LKA_2009_HIES_v01_M_v02_A_SARMD.log",replace


/*****************************************************************************************************
*                                                                                                    *
                                   * ASSEMBLE DATABASE
*                                                                                                    *
*****************************************************************************************************/


** DATABASE ASSEMBLENT

* PREPARE DATABASES

* School Education
	use "`input'\Data\Stata\hies_2009_sec2_school.dta", clear
	sort district sector dsdiv month psu sample serial numhh result pno
	tempfile education
	save `education'
	
* Employment & Income
	use "`input'\Data\Stata\hies_2009_sec5_1_empincome.dta",clear
	sort district sector dsdiv month psu sample serial numhh result pno
	bys district sector dsdiv month psu sample serial numhh result pno: gen n=_n
	replace n=n-1
	bys district sector dsdiv month psu sample serial numhh result pno: egen njobs=max(n)
	drop if main_sec==2
	sort district sector dsdiv month psu sample serial numhh result pno wage_1m
	duplicates tag district sector dsdiv month psu sample serial numhh result pno, gen(tag)
	drop if tag==1 & main_sec==.
	drop main_sec tag n
	tempfile employment
	save `employment'
	
*Housing
	use "`input'\Data\Stata\hies_2009_sec8_housing.dta", clear
	sort district sector dsdiv month psu sample serial numhh result
	tempfile housing
	save `housing'

* MERGE

* Demographic
	use "`input'\Data\Stata\hies_2009_sec1_demo.dta"
	sort district sector dsdiv month psu sample serial numhh result pno

* School Education
	merge district sector dsdiv month psu sample serial numhh result pno using `education'
	tab 	_merge
	drop 	_merge
	sort district sector dsdiv month psu sample serial numhh result pno

* Employmen & Income
	merge district sector dsdiv month psu sample serial numhh result pno using `employment'
	tab 	_merge
	drop 	_merge
	sort district sector dsdiv month psu sample serial numhh result pno

*Housing
	merge district sector dsdiv month psu sample serial numhh result using `housing'
	tab 	_merge
	drop 	_merge

* Consumption Aggregate
	assert hhid != ""
	lab var hhid "household id"

	ren province province_str
	merge m:1 hhid using "`input'\Data\Stata\wfile2009.dta"
	tab _merge
	
	
* Drop people not living in the house
	drop if pno>=40

	
/*****************************************************************************************************
*                                                                                                    *
                                   * STANDARD SURVEY MODULE
*                                                                                                    *
*****************************************************************************************************/

	
** COUNTRY
*<_countrycode_>
	gen str4 countrycode="LKA"
	label var countrycode "Country code"
*</_countrycode_>


** YEAR
*<_year_>
	gen int year=2009
	label var year "Year of survey"
*</_year_>


** SURVEY NAME 
*<_survey_>
	gen str survey="HIES"
	label var survey "Survey Acronym"
*</_survey_>



** INTERVIEW YEAR
*<_int_year_>
	gen byte int_year=.
	label var int_year "Year of the interview"
*</_int_year_>
	
	
** INTERVIEW MONTH
*<_int_month_>
	gen byte int_month=month
	la de lblint_month 1 "January" 2 "February" 3 "March" 4 "April" 5 "May" 6 "June" 7 "July" 8 "August" 9 "September" 10 "October" 11 "November" 12 "December"
	label value int_month lblint_month
	label var int_month "Month of the interview"
*</_int_month_>
	

** HOUSEHOLD IDENTIFICATION NUMBER
*<_idh_>
	egen   idh=concat(district sector dsdiv month psu sample serial numhh result)
	label var idh "Household id"
*</_idh_>


** INDIVIDUAL IDENTIFICATION NUMBER
*<_idp_>

	egen idp=concat(idh pno)
	label var idp "Individual id"
*</_idp_>
	duplicates drop idp,force

	
** HOUSEHOLD WEIGHTS
*<_wgt_>
	gen double wgt=weight
	label var wgt "Household sampling weight"
*</_wgt_>


** STRATA
*<_strata_>
	gen strata=.
	label var strata "Strata"
*</_strata_>


** PSU
*<_psu_>
	label var psu "Primary sampling units"
*</_psu_>

	
** MASTER VERSION
*<_vermast_>

	gen vermast="02"
	label var vermast "Master Version"
*</_vermast_>
	
	
** ALTERATION VERSION
*<_veralt_>

	gen veralt="01"
	label var veralt "Alteration Version"
*</_veralt_>	
	
/*****************************************************************************************************
*                                                                                                    *
                                   FIX ISSUES WITHIN THE RAW DATA
*                                                                                                    *
*****************************************************************************************************/


* More than one houosehold head
	gen hdind=(relation==1)
	recode hdind (0=.)
	bysort idh : egen count=count(hdind)

	replace relation=5 if count!=1 & relation==1 & pno!=1
	drop count hdind

	
/*****************************************************************************************************
*                                                                                                    *
                                   HOUSEHOLD CHARACTERISTICS MODULE
*                                                                                                    *
*****************************************************************************************************/


** LOCATION (URBAN/RURAL)
*<_urban_>
	gen byte urban=sector
	recode urban (2 3=0)
	label var urban "Urban/Rural"
	la de lblurban 1 "Urban" 0 "Rural"
	label values urban lblurban
*</_urban_>

** LOCATION (ESTATE)
*<_sector_>
*	gen byte sector=sector
	label define lblsector 1 "Urban" 2 "Rural" 3 "Estate"
	label values sector lblsector
	label var sector "Sector (Sri Lanka)"
*</_sector_>


** REGIONAL AREA 1 DIGIT ADMN LEVEL
*<_subnatid1_>
	gen byte subnatid1=district
	recode subnatid1 (11/13=1) (21/23=2) (31/33=3) (41/45=4) (51/53=5) (61/62=6) (71/72=7) (81/82=8) (91/92=9)
	la de lblsubnatid1 1 "Western" 2 "Central" 3 "Southern" 4 "Northern" 5 "Eastern" 6 "North-Western" 7"North-Central" 8"Uva" 9"Sabaragamuwa"
	label var subnatid1 "Macro regional areas"
	label values subnatid1 lblsubnatid1
*</_subnatid1_>


** REGIONAL AREA 2 DIGIT ADMN LEVEL
*<_subnatid2_>
	gen byte subnatid2=district
	la de lblsubnatid2  11 "Colombo" 12 "Gampaha" 13 "Kalutara" 21 "Kandy" 22 "Matale" 23 "Nuwara-eliya" 31 "Galle" 32 "Matara" 33 "Hambantota" 41 "Jaffna" 42 "Mannar" 43 "Vavuniya" 44 "Mullaitivu" 45 "Kilinochchi" 51 "Batticaloa" 52 "Ampara" 53 "Tricomalee" 61 "Kurunegala" 62 "Puttlam" 71 "Anuradhapura" 72 "Polonnaruwa" 81 "Badulla" 82 "Moneragala" 91 "Ratnapura" 92 "Kegalle"
	label var subnatid2 "Region at 1 digit (ADMN1)"
	label values subnatid2 lblsubnatid2
*</_subnatid2_>


** REGIONAL AREA 3 DIGIT ADMN LEVEL
*<_subnatid3_>
	gen byte subnatid3=.
	label var subnatid3 "Region at 3 digit (ADMN3)"
	label values subnatid3 lblsubnatid3
*</_subnatid3_>


** HOUSE OWNERSHIP
*<_ownhouse_>
	gen byte ownhouse=ownership
	recode ownhouse (1/4=1) (5/99=0)
	label var ownhouse "House ownership"
	la de lblownhouse 0 "No" 1 "Yes"
	label values ownhouse lblownhouse
*</_ownhouse_>

** WATER PUBLIC CONNECTION
*<_water_>
	gen byte water=drinkwat
	recode water (5 6 7=1) (1 2 3 4 8 9=0)
	label var water "Water main source"
	la de lblwater 0 "No" 1 "Yes"
	label values water lblwater
*</_water_>

** ELECTRICITY PUBLIC CONNECTION
*<_electricity_>

	gen byte electricity=lighting
	recode electricity (2=1) (1 3 4 9=0)
	label var electricity "Electricity main source"
	la de lblelectricity 0 "No" 1 "Yes"
	label values electricity lblelectricity
*</_electricity_>

** TOILET PUBLIC CONNECTION
*<_toilet_>

	gen byte toilet=toilettype
	recode toilet (1 2=1) (3 4=0) (9=.)
	label var toilet "Toilet facility"
	la de lbltoilet 0 "No" 1 "Yes"
	label values toilet lbltoilet
*</_toilet_>


** LAND PHONE
*<_landphone_>

	gen byte landphone=.
	label var landphone "Phone availability"
	la de lbllandphone 0 "No" 1 "Yes"
	label values landphone lbllandphone
*</_landphone_>


** CEL PHONE
*<_cellphone_>

	gen byte cellphone=.
	label var cellphone "Cell phone"
	la de lblcellphone 0 "No" 1 "Yes"
	label values cellphone lblcellphone
*</_cellphone_>


** COMPUTER
*<_computer_>
	gen byte computer=.
	label var computer "Computer availability"
	la de lblcomputer 0 "No" 1 "Yes"
	label values computer lblcomputer
*</_computer_>


** INTERNET
	gen byte internet=.
	label var internet "Internet connection"
	la de lblinternet 0 "No" 1 "Yes"
	label values internet lblinternet


/*****************************************************************************************************
*                                                                                                    *
                                   DEMOGRAPHIC MODULE
*                                                                                                    *
*****************************************************************************************************/


** HOUSEHOLD SIZE
*<_hsize_>

	bysort idh : egen hsize=count(pno) 
	la var hsize "Household size"
*</_hsize_>


** RELATIONSHIP TO THE HEAD OF HOUSEHOLD
*<_relationharm_>
	gen byte relationharm=relation
	recode relationharm ( 6/9=6)
	label var relationharm "Relationship to the head of household"
	la de lblrelationharm  1 "Head of household" 2 "Spouse" 3 "Children" 4 "Parents" 5 "Other relatives" 6 "Non-relatives"
	label values relationharm  lblrelationharm
*</_relationharm_>

** RELATIONSHIP TO THE HEAD OF HOUSEHOLD
*<_relationcs_>

	gen byte relationcs=relation
	la var relationcs "Relationship to the head of household country/region specific"
	la define lblrelationcs 1 "Head" 2 "Wife/Husband" 3 "Son/Daughter" 4 "Parents" 5 "Other relative" 6 "Domestic servants" 7 "Boarder" 9 "Other"
	label values relationcs lblrelationcs
*</_relationcs_>


** GENDER
*<_male_>
	gen byte male=sex
	recode male (2=0)
	label var male "Sex of household member"
	la de lblmale 1 "Male" 0 "Female"
	label values male lblmale
*</_male_>


** AGE
*<_age_>
	* Generate Age based on Month and Year of Birth for missing cases
	* 99.5% of cases turns out to be 0 == babies
	gen 	year_interview=2009 if month>=7 & month!=.
	replace year_interview=2010 if month<=6
	gen birth_year_b=.
	replace birth_year_b=2000 if birth_year<=10
	replace birth_year_b=1900 if birth_year>10 & birth_year!=.
	replace birth_year=birth_year+birth_year_b
	gen dob=mdy(b_month,1,birth_year)
	gen date=mdy(month,1,year_interview)
	gen age_date=int((date-dob)/365)
	replace age=age_date if age==. & age_date!=.
	label var age "Age of individual"
*</_age_>

** SOCIAL GROUP
*<_soc_>
	gen byte soc=ethnic
	recode soc (9=7)
	label var soc "Social group"
	la de lblsoc 1 "Sinhala" 2"Sri Lanka Tamil" 3"Indian Tamil" 4"Sri Lanka Moors" 5"Malay" 6"Burgher" 7"Other"
	label values soc lblsoc
*</_soc_>

** MARITAL STATUS
*<_marital_>*	gen byte marital=marital_status
	recode marital (1=2) (2=1) (3=5) (4/5=4)
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
	gen byte ed_mod_age=5
	label var ed_mod_age "Education module application age"
*</_ed_mod_age_>


** CURRENTLY AT SCHOOL
*<_atschool_>
	gen byte atschool=1 if s_attend==1
	replace atschool=0 if s_attend==2 | s_attend==3 | education==19
	replace atschool=1 if school>=2 & school<=5
	replace atschool=0 if school==7
	label var atschool "Attending school"
	la de lblatschool 0 "No" 1 "Yes"
	label values atschool  lblatschool
*</_atschool_>


** CAN READ AND WRITE
*<_literacy_>
	gen byte literacy=.
	label var literacy "Can read & write"
	la de lblliteracy 0 "No" 1 "Yes"
	label values literacy lblliteracy
*</_literacy_>

	replace education=. if education==17


** YEARS OF EDUCATION COMPLETED
*<_educy_>
	gen byte educy=education
	recode educy (19 = 0) (14=13) (15 = 17) (16 = 19) (17=.)
	label var educy "Years of education"
*</_educy_>
	replace educy=0 if education==19
	replace educy=. if educy>=age-2 & educy!=. & age!=.
	replace age=. 	if educy>=age-2 & educy!=. & age!=.

	
** EDUCATION LEVEL 7 CATEGORIES
*<_educat7_>
	gen byte educat7=education
	recode educat7 (19 = 1) (0/5 = 2) (6 = 3) (7/10 = 4) (11/14 = 5) (15/16 = 7) (17=.)
	replace educat7=7 if school==3
	replace educat7=. if age<5
	label define lbleducat7 1 "No education" 2 "Primary incomplete" 3 "Primary complete" ///
	4 "Secondary incomplete" 5 "Secondary complete" 6 "Higher than secondary but not university" /// 
	7 "University incomplete or complete" 8 "Other" 9 "Not classified"
	label values educat7 lbleducat7
	la var educat7 "Level of education 7 categories"
*</_educat7_>



** EDUCATION LEVEL 5 CATEGORIES
*<_educat5_>
	gen educat5=.
	replace educat5=1 if educat7==1
	replace educat5=2 if educat7==2
	replace educat5=3 if educat7==3 | educat7==4
	replace educat5=4 if educat7==5
	replace educat5=5 if educat7==6 | educat7==7
	replace educat5=5 if school==3
	label define lbleducat5 1 "No education" 2 "Primary incomplete" ///
	3 "Primary complete but secondary incomplete" 4 "Secondary complete" ///
	5 "Some tertiary/post-secondary"
	label values educat5 lbleducat5
*</_educat5_>

	la var educat5 "Level of education 5 categories"

	
** EDUCATION LEVEL 4 CATEGORIES
*<_educat4_>
	gen byte educat4=.
	replace educat4=1 if educat7==1 
	replace educat4=2 if educat7==2 | educat7==3
	replace educat4=3 if educat7==4 | educat7==5
	replace educat4=4 if educat7==6 | educat7==7
	replace educat4=4 if school==3
	label var educat4 "Level of education 4 categories"
	label define lbleducat4 1 "No education" 2 "Primary (complete or incomplete)" ///
	3 "Secondary (complete or incomplete)" 4 "Tertiary (complete or incomplete)"
	label values educat4 lbleducat4
*</_educat4_>


	
** EVER ATTENDED SCHOOL
*<_everattend_>
	gen byte everattend=0 if s_attend==2
	replace everattend=1 if atschool==1 | s_attend==3
	replace everattend=0 if educat4==1
	replace everattend=1 if educat4!=1 & educat4!=.
	label var everattend "Ever attended school"
	la de lbleverattend 0 "No" 1 "Yes"
	label values everattend lbleverattend
*</_everattend_>


	
foreach var in atschool literacy everattend educat4 educat5 educat7{
replace `var'=. if age<ed_mod_age
}

/*****************************************************************************************************
*                                                                                                    *
                                   LABOR MODULE
*                                                                                                    *
*****************************************************************************************************/


** LABOR MODULE AGE
*<_lb_mod_age_>

 gen byte lb_mod_age=10
	label var lb_mod_age "Labor module application age"
*</_lb_mod_age_>



** LABOR STATUS
*<_lstatus_>
	gen byte lstatus=cur_act
	recode lstatus (3 4 5 6=3) (9=.)

	label var lstatus "Labor status"
	la de lbllstatus 1 "Employed" 2 "Unemployed" 3 "Non-LF"
	label values lstatus lbllstatus
*</_lstatus_>


** EMPLOYMENT STATUS
*<_empstat_>
	gen byte empstat=emp_stat
	recode empstat (1 2 3=1) (6=2) (4=3) (5=4) (9=.)
	label var empstat "Employment status"
	la de lblempstat 1 "Paid employee" 2 "Non-paid employee" 3 "Employer" 4 "Self-employed"
	label values empstat lblempstat
*</_empstat_>
	replace empstat=. if lstatus!=1

** SECTOR OF ACTIVITY: PUBLIC - PRIVATE
*<_njobs_>
	label var njobs "Number of additional jobs"
*</_njobs_>


** SECTOR OF ACTIVITY: PUBLIC - PRIVATE
*<_ocusec_>
	gen byte ocusec=emp_stat
	recode ocusec (2=1) (3/6=2) (9=.)
	label var ocusec "Sector of activity"
	la de lblocusec 1 "Public, state owned, government, army, NGO" 2 "Private"
	label values ocusec lblocusec
*</_ocusec_>
	replace ocusec=. if lstatus!=1

** REASONS NOT IN THE LABOR FORCE
*<_nlfreason_>
	gen byte nlfreason=.
	replace nlfreason=1 if cur_act==3
	replace nlfreason=2 if cur_act==4
	replace nlfreason=5 if cur_act==5 | cur_act==6 | cur_act==9

	label var nlfreason "Reason not in the labor force"
	la de lblnlfreason 1 "Student" 2 "Housewife" 3 "Retired" 4 "Disable" 5 "Other"
	label values nlfreason lblnlfreason
*</_nlfreason_>	replace nlfreason=. if lstatus!=3

** UNEMPLOYMENT DURATION: MONTHS LOOKING FOR A JOB
*<_unempldur_l_>
	gen byte unempldur_l=.
	label var unempldur_l "Unemployment duration (months) lower bracket"
*</_unempldur_l_>

*<_unempldur_u_>

	gen byte unempldur_u=.
	label var unempldur_u "Unemployment duration (months) upper bracket"
*</_unempldur_u_>
	tostring main_ind, gen (stringind)
	rename main_ind inddus

** INDUSTRY CLASSIFICATION
*<_industry_>
	gen byte industry=.
	gen induus=real(substr(stringind,1,2)) if  inddus>=700

	replace industry=1 if inddus<=700
	replace industry=2 if induus>=10 & induus<=14
	replace industry=3 if induus>=15 & induus<=36
	replace industry=4 if induus==40 | induus==41
	replace industry=5 if induus==45
	replace industry=6 if induus>=50 & induus<=55
	replace industry=7 if induus>=60 & induus<=64
	replace industry=8 if induus>=65 & induus<=74
	replace industry=9 if induus>=75& induus<=75
	replace industry=10 if induus>75 & induus<=99
	replace industry=10 if industry==. & induus!=.

	label var industry "1 digit industry classification"
	la de lblindustry 1 "Agriculture" 2 "Mining" 3 "Manufacturing" 4 "Public utilities" 5 "Construction"  6 "Commerce" 7 "Transports and comnunications" 8 "Financial and business-oriented services" 9 "Public Administration" 10 "Other services, unspecified"
	label values industry lblindustry
*</_industry_>
	replace industry=. if lstatus!=1

** OCCUPATION CLASSIFICATION
*<_occup_>
	gen byte occup=.
	tostring main_occ,gen(stringmain)
	gen numoccup=real(substr(stringmain,1,2)) if main_occ>=150
	replace occup=1 if numoccup>=10 & numoccup<=13
	replace occup=2 if numoccup>=20 & numoccup<=24 
	replace occup=3 if numoccup>=30 & numoccup<=34
	replace occup=4 if numoccup==41 | numoccup==42
	replace occup=5 if numoccup==51 | numoccup==52
	replace occup=6 if numoccup==61
	replace occup=7 if numoccup>=71 & numoccup<=74
	replace occup=8 if numoccup>=80 & numoccup<=83
	replace occup=9 if numoccup>=90 & numoccup<=93
	replace occup=10 if main_occ==110
	label var occup "1 digit occupational classification"
	la de lbloccup 1 "Senior officials" 2 "Professionals" 3 "Technicians" 4 "Clerks" 5 "Service and market sales workers" 6 "Skilled agricultural" 7 "Craft workers" 8 "Machine operators" 9 "Elementary occupations" 10 "Armed forces"  99 "Others"
	label values occup lbloccup
*</_occup_>
	replace occup=. if lstatus!=1

** FIRM SIZE
*<_firmsize_l_>
	gen byte firmsize_l=.
	label var firmsize_l "Firm size (lower bracket)"
*</_firmsize_l_>

*<_firmsize_u_>

	gen byte firmsize_u=.
	label var firmsize_u "Firm size (upper bracket)"

*</_firmsize_u_>


** HOURS WORKED LAST WEEK
*<_whours_>
	gen whours=.
	label var whours "Hours of work in last week"
*</_whours_>


** WAGES
*<_wage_>
	gen double wage=wage_1m // LAST MONTH
	label var wage "Last wage payment"
*</_wage_>
	replace wage=. if lstatus!=1

** WAGES TIME UNIT
*<_unitwage_>
	gen byte unitwage=5
	label var unitwage "Last wages time unit"
	la de lblunitwage 1 "Daily" 2 "Weekly" 3 "Every two weeks" 4 "Bimonthly"  5 "Monthly" 6 "Quarterly" 7 "Biannual" 8 "Annually" 9 "Hourly" 10 "Other"
	label values unitwage lblunitwage
*</_wageunit_>
	replace unitwage=. if lstatus!=1

** CONTRACT
*<_contract_>
	gen byte contract=.
	label var contract "Contract"
	la de lblcontract 0 "Without contract" 1 "With contract"
	label values contract lblcontract
*</_contract_>


** HEALTH INSURANCE
*<_healthins_>
	gen byte healthins=.
	label var healthins "Health insurance"
	la de lblhealthins 0 "Without health insurance" 1 "With health insurance"
	label values healthins lblhealthins
*</_healthins_>


** SOCIAL SECURITY
*<_socialsec_>
	gen byte socialsec=.
	label var socialsec "Social security"
	la de lblsocialsec 1 "With" 0 "Without"
	label values socialsec lblsocialsec
*</_socialsec_>


** UNION MEMBERSHIP
*<_union_>
	gen byte union=.
	label var union "Union membership"
	la de lblunion 0 "No member" 1 "Member"
	label values union lblunion
*</_union_>

	
/*****************************************************************************************************
*                                                                                                    *
                                   WELFARE MODULE
*                                                                                                    *
*****************************************************************************************************/


** SPATIAL DEFLATOR
*<_spdef_>
	gen spdef=rpccons/npccons
	la var spdef "Spatial deflator"
*</_spdef_>

** WELFARE
*<_welfare_>
	gen welfare=npccons
	la var welfare "Welfare aggregate"
*</_welfare_>

*<_welfarenom_>
	gen welfarenom=npccons
	la var welfarenom "Welfare aggregate in nominal terms"
*</_welfarenom_>

*<_welfaredef_>
	gen welfaredef=rpccons
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
	gen welfareother=.
	la var welfareother "Welfare Aggregate if different welfare type is used from welfare, welfarenom, welfaredef"
*</_welfareother_>

*<_welfareothertype_>
	gen welfareothertype=""
	la var welfareothertype "Type of welfare measure (income, consumption or expenditure) for welfareother"
*</_welfareothertype_>

*<_welfarenat_>
	gen welfarenat=rpccons
	la var welfarenat "Welfare aggregate for national poverty"
*</_welfarenat_>	
/*****************************************************************************************************
*                                                                                                    *
                                   NATIONAL POVERTY
*                                                                                                    *
*****************************************************************************************************/

	
** POVERTY LINE (NATIONAL)
*<_pline_nat_>
	gen pline_nat=3028
	label variable pline_nat "Poverty Line (National)"
*</_pline_nat_>


** HEADCOUNT RATIO (NATIONAL)
*<_poor_nat_>
	gen poor_nat=welfarenat<pline_nat if welfarenat!=.
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
	gen urb=.
	merge m:1 countrycode year urb using "D:\SOUTH ASIA MICRO DATABASE\DOCS\CPI and PPP\cpi_ppp_sarmd.dta", ///
	keepusing(countrycode year urb syear cpi`year'_w ppp`year')
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

	keep countrycode year survey idh idp wgt strata psu vermast veralt urban sector int_month int_year ///
		subnatid1 subnatid2 subnatid3 ownhouse water electricity toilet landphone cellphone ///
	     computer internet hsize relationharm relationcs male age soc marital ed_mod_age everattend ///
	     atschool electricity literacy educy educat4 educat5 educat7 lb_mod_age lstatus empstat njobs ///
	     ocusec nlfreason unempldur_l unempldur_u industry occup firmsize_l firmsize_u whours wage ///
		 unitwage contract healthins socialsec union pline_nat pline_int poor_nat poor_int spdef cpi ppp ///
		 cpiperiod welfare welfarenom welfaredef welfarenat welfareother welfaretype welfareothertype

** ORDER VARIABLES

	order countrycode year survey idh idp wgt strata psu vermast veralt urban sector int_month int_year ///
		subnatid1 subnatid2 subnatid3 ownhouse water electricity toilet landphone cellphone ///
	      computer internet hsize relationharm relationcs male age soc marital ed_mod_age everattend ///
	      atschool electricity literacy educy educat4 educat5 educat7 lb_mod_age lstatus empstat njobs ///
	      ocusec nlfreason unempldur_l unempldur_u industry occup firmsize_l firmsize_u whours wage ///
		 unitwage contract healthins socialsec union pline_nat pline_int poor_nat poor_int spdef cpi ppp ///
		 cpiperiod welfare welfarenom welfaredef welfarenat welfareother welfaretype welfareothertype
	
	compress

** DELETE MISSING VARIABLES

	local keep ""
	qui levelsof countrycode, local(cty)
	foreach var of varlist urban - welfareother {
	qui sum `var'
	scalar sclrc = r(mean)
	if sclrc==. {
	     display as txt "Variable " as result "`var'" as txt " for countrycode " as result `cty' as txt " contains all missing values -" as error " Variable Deleted"
	}
	else {
	     local keep `keep' `var'
	}
	}
	
	foreach w in welfare welfareother{
	qui su `w'
	if r(N)==0{
	drop `w'type
}
}
	keep countrycode year survey idh idp wgt strata psu vermast veralt `keep' *type
	compress

	saveold "`output'\Data\Harmonized\LKA_2009_HIES_v01_M_v02_A_SARMD_IND.dta", replace version(12)
	saveold "D:\SOUTH ASIA MICRO DATABASE\SAR_DATABANK\__REGIONAL\Individual Files\LKA_2009_HIES_v01_M_v02_A_SARMD_IND.dta", replace version(12)


	log close




******************************  END OF DO-FILE  *****************************************************/
