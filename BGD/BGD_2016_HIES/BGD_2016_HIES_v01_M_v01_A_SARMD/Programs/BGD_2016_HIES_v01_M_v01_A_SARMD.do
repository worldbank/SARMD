******************************************************************************************************
/*****************************************************************************************************
**                                                                                                  **
**                                   SOUTH ASIA MICRO DATABASE                                      **
**                                                                                                  **
** COUNTRY			 Bangladesh
** COUNTRY ISO CODE	 BGD
** YEAR				 2016
** SURVEY NAME		 HOUSEHOLD INCOME AND EXPENDITURE SURVEY-2016
** SURVEY AGENCY	 BANGLADESH BUREAU OF STATISTICS
** RESPONSIBLE		 Julian Eduardo Diaz-Gutierrez
** MODIFIED BY       Fernando Enrique Morales Velandia
** CREATION DATE	 08/24/2017
** MODIFICATION DATE 1/23/2018
**
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
	set more off, perm

** DIRECTORY
	glo input "D:\SOUTH ASIA MICRO DATABASE\SAR_DATABANK\BGD\BGD_2016_HIES\BGD_2016_HIES_v01_M"
	glo output "D:\SOUTH ASIA MICRO DATABASE\SAR_DATABANK\BGD\BGD_2016_HIES\BGD_2016_HIES_v01_M_v01_A_SARMD"
	glo pricedata "D:\SOUTH ASIA MICRO DATABASE\CPI\cpi_ppp_sarmd_weighted.dta"
	glo shares "D:\SOUTH ASIA MICRO DATABASE\APPS\DATA CHECK\Food and non-food shares\BGD"
	glo fixlabels "D:\SOUTH ASIA MICRO DATABASE\APPS\DATA CHECK\Label fixing"

** LOG FILE
	*log using "${output}\Doc\Technical\BGD_2016_HIES_v01_M_v01_A_SARMD.log", replace


/*****************************************************************************************************
*                                                                                                    *
                                   * ASSEMBLE DATABASE
*                                                                                                    *
*****************************************************************************************************/

	** ROASTER
	use "${input}\Data\Stata\Old version Raw Data\HH_SEC_1A_Q1Q2Q3Q4", clear
	tempfile roster
	ren s1aq00 idp
	sort hhold idp
	duplicates report idp hhold s1aq01 s1aq03 s1aq02 s1aq05 
	duplicates drop idp hhold s1aq01 s1aq03 s1aq02 s1aq05, force
	egen member1= count(idp), by(hhold)
	drop if member1==0
	drop if idp==.
	save `roster', replace
	
	** EMPLOYMENT 
	use "${input}\Data\Stata\Old version Raw Data\HH_SEC_1B_Q1Q2Q3Q4", clear
	tempfile employment
	ren s1bq00 idp
	sort hhold idp
	drop if idp==.
	duplicates report idp hhold
	save `employment', replace
	
	
	** WAGE EMPLOYMENT
	use "${input}\Data\Stata\Old version Raw Data\HH_SEC_4A_Q1Q2Q3Q4",clear
	tempfile wage_employment
	ren s4aq00 idp
	sort idp hhold
	keep psu hhold hhwgt idp s4aq01b s4aq01c s4aq02 s4aq03 s4aq04  s4aq07 s4aq08
	drop if idp==.
	
	  *Drop people without reported time in the survey
	  drop if s4aq02==. & s4aq03==. & s4aq04==.
	  *Keep main activity
	  bys psu hhold idp: egen max_month=max(s4aq02)
	  bys psu hhold idp: egen max_day=max(s4aq03)
	  bys psu hhold idp: egen max_hour=max(s4aq04) 
	  
	  *Number of jobs
	  gen one=1
	  bys psu hhold idp: egen njobs=total(one)
	  
	  duplicates tag psu hhold idp, gen(tag)
	  keep if tag==0 | (tag!=0 & max_month==s4aq02)
	  
	  duplicates tag psu hhold idp, gen(tag2)
	  keep if tag2==0 | (tag2!=0 & max_day==s4aq03)
	  
	  duplicates tag psu hhold idp, gen(tag3)
	  keep if tag3==0 | (tag3!=0 & max_hour==s4aq04)
	  
	  duplicates report psu hhold idp max_month max_day max_hour
	  duplicates drop psu hhold idp max_month max_day max_hour, force
	  
	  duplicates report hhold idp
	  drop tag* max*
	  

	  duplicates report psu hhold idp
	  
	  save `wage_employment', replace
	  
	  *Merge with section B.
	  use "${input}\Data\Stata\Old version Raw Data\HH_SEC_4B_Q1Q2Q3Q4",clear
	  ren s4bq00 idp
	  sort idp hhold
	  
	  *Keep highest paying activity
	  gen wage=.
	  replace wage=s4bq02c if s4bq01==1
	  replace wage=s4bq08 if s4bq01==1
	  
	  bys psu hhold idp: egen wage_max=max(wage)
	  bys psu hhold idp: gen n=_n
	  
	  duplicates tag psu hhold idp, gen(tag)
	  
	  drop if tag==1 & wage_max==. & n==2
	  keep if tag==0 | (tag==1 & (wage_max==s4bq02c | wage_max==s4bq08))
	  
	  drop if tag==1 & n==2
	  drop if idp==.
	  duplicates report idp hhold psu
	  
	  merge 1:m hhold idp psu using `wage_employment'
	  drop _merge
	  
	  save `wage_employment', replace
	  
			
	*Education (Literacy and attainment)
	use "${input}\Data\Stata\Old version Raw Data\HH_SEC_2A_Q1Q2Q3Q4", clear
	tempfile education_all
	ren s2aq00 idp
	sort hhold idp
	drop if idp==.
	duplicates report idp hhold s2aq01 s2aq02 s2aq04 s2aq03
	duplicates drop idp hhold s2aq01 s2aq02 s2aq04 s2aq03, force
	save `education_all', replace
	
	
	*Education (Current enrollment)
	use "${input}\Data\Stata\Old version Raw Data\HH_SEC_2B_Q1Q2Q3Q4",clear
	tempfile education_current
	ren s2bq00 idp	
	sort hhold idp
	drop if idp==.
	duplicates report hhold idp s2bq01 s2bq03 s2bq02
	duplicates drop hhold idp s2bq01 s2bq03 s2bq02, force
	save `education_current', replace
	
	
	*Assets (material)
	use "${input}\Data\Stata\Old version Raw Data\HH_SEC_9E_Q1Q2Q3Q4.dta", clear
	tempfile assets
	drop if s9eq00==.
	gen assets=1 if s9eq01b=="X"
	replace assets=0 if s9eq01a=="X"
	replace assets=1 if s9eq02!=.
	*Some cases of mismatch data (the data doesn't allows us to classify if the person has the asset)
	replace assets=. if s9eq01b=="X" & s9eq01a=="X" 
	replace assets=. if s9eq01a=="X" & s9eq02!=.
	replace assets=. if assets==1 & s9eq02==.
	replace assets=. if assets==0 & s9eq02!=.
	
	keep hhold assets s9eq00
	* Clasification of assets according to the rawdata
/*	
tab s9eq00

                         Item Code |      Freq.     Percent        Cum.
-----------------------------------+-----------------------------------
                             Radio |     45,888        3.57        3.57
       Two-in-one, Cassette player |     45,874        3.57        7.14
                 Camera/ camcorder |     45,874        3.57       10.72
                           Bicycle |     45,874        3.57       14.29
               Motorcycle/ scooter |     45,874        3.57       17.86
                    Motor car etc. |     45,873        3.57       21.43
           Refrigerator or freezer |     45,873        3.57       25.00
                   Washing machine |     45,873        3.57       28.57
                              Fans |     45,873        3.57       32.14
                           Heaters |     45,873        3.57       35.72
                        Television |     45,873        3.57       39.29
                      VCR/ VCP/DVD |     45,873        3.57       42.86
              Dish antena/ decoder |     45,873        3.57       46.43
          Pressure lamps/ petromax |     45,873        3.57       50.00
                    Sewing machine |     45,873        3.57       53.57
                 Bedroom Furniture |     45,873        3.57       57.14
            Drawing room Furniture |     45,872        3.57       60.72
             Dining room Furniture |     45,872        3.57       64.29
                            Carpet |     45,872        3.57       67.86
           Kitchen Items - Cutlery |     45,872        3.57       71.43
          Kitchen Items - Crockery |     45,872        3.57       75.00
 Mocrooven/Kitchen Items - Cooking |     45,872        3.57       78.57
Tubewell (for drinking water only) |     45,872        3.57       82.14
            Wrist watch/Wall clock |     45,872        3.57       85.72
                            Mobile |     45,872        3.57       89.29
                  Computer/TV Card |     45,871        3.57       92.86
                       Boat/Others |     45,868        3.57       96.43
                             Total |     45,868        3.57      100.00
-----------------------------------+-----------------------------------
                             Total |  1,284,442      100.00

. tab s9eq00, nol

  Item Code |      Freq.     Percent        Cum.
------------+-----------------------------------
        571 |     45,888        3.57        3.57
        572 |     45,874        3.57        7.14
        573 |     45,874        3.57       10.72
        574 |     45,874        3.57       14.29
        575 |     45,874        3.57       17.86
        576 |     45,873        3.57       21.43
        577 |     45,873        3.57       25.00
        578 |     45,873        3.57       28.57
        579 |     45,873        3.57       32.14
        581 |     45,873        3.57       35.72
        582 |     45,873        3.57       39.29
        583 |     45,873        3.57       42.86
        584 |     45,873        3.57       46.43
        585 |     45,873        3.57       50.00
        586 |     45,873        3.57       53.57
        587 |     45,873        3.57       57.14
        588 |     45,872        3.57       60.72
        589 |     45,872        3.57       64.29
        591 |     45,872        3.57       67.86
        592 |     45,872        3.57       71.43
        593 |     45,872        3.57       75.00
        594 |     45,872        3.57       78.57
        595 |     45,872        3.57       82.14
        596 |     45,872        3.57       85.72
        597 |     45,872        3.57       89.29
        598 |     45,871        3.57       92.86
        599 |     45,868        3.57       96.43
        600 |     45,868        3.57      100.00
------------+-----------------------------------
      Total |  1,284,442      100.00
*/

	*Keep assets that are used in the harmonized variables
	keep if s9eq00==571 | s9eq00==598 | s9eq00==582 | s9eq00==579 | s9eq00==586 ///
	 | s9eq00==578  | s9eq00==585  | s9eq00==574 | s9eq00==575 | s9eq00==576 | s9eq00==577
	 	 
	reshape wide assets, i(hhold) j(s9eq00)
	duplicates report hhold
	save `assets', replace 
	
	
	*Assets (animals)
	use "${input}\Data\Stata\Old version Raw Data\HH_SEC_7C1_Q1Q2Q3Q4", clear	
	tempfile assets_animal
	sort hhold

	*Keep assets that are used in the harmonized variables (cow, buffalo and chicken)
	keep if s7c1q00==201 | s7c1q00==204 | s7c1q00==205
	keep hhold s7c1q02a s7c1q00
	replace s7c1q02a=1 if s7c1q02a>=1 & s7c1q02a!=.
	replace s7c1q02a=0 if s7c1q02a==.
	reshape wide s7c1q02a, i(hhold) j(s7c1q00)
	duplicates report hhold
	save `assets_animal', replace
	
	*Consumption
	use "${input}\Data\Stata\Old version Raw Data\poverty_indicators2016", clear
	tempfile consumption
	sort hhold
	duplicates report hhold
	save `consumption', replace
	
	*Housing
	use "${input}\Data\Stata\Old version Raw Data\HH_SEC_6A_Q1Q2Q3Q4", clear
	tempfile housing
	sort hhold
	duplicates report hhold
	save `housing', replace
	
	*Land
	use "${input}\Data\Stata\Old version Raw Data\HH_SEC_7A_Q1Q2Q3Q4", clear
	tempfile land
	sort hhold
	duplicates report hhold
	save `land', replace
	
	
	*MERGE DATASETS
	
	*-Individual-level datasets
	
	use `roster', clear
	
	foreach i in employment education_all education_current wage_employment {
		merge m:1 hhold idp using  ``i'', keep(1 3) nogen
	}
	
	*-Household-level datasets
	
	foreach j in housing consumption assets assets_animal land {
		merge m:1 hhold using ``j'', keep(1 3) nogen
	}
	
	order hhold idp psu hhwgt
	sort hhold idp
	ren idp idp1
	
/*****************************************************************************************************
*                                                                                                    *
                                   * STANDARD SURVEY MODULE
*                                                                                                    *
*****************************************************************************************************/
	
	
** COUNTRY
*<_countrycode_>
	gen str4 countrycode="BGD"
	label var countrycode "Country code"
*</_countrycode_>


** YEAR
*<_year_>
	cap drop year
	gen int year=2016
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
	gen byte int_month=.
	la de lblint_month 1 "January" 2 "February" 3 "March" 4 "April" 5 "May" 6 "June" 7 "July" 8 "August" 9 "September" 10 "October" 11 "November" 12 "December"
	label value int_month lblint_month
	label var int_month "Month of the interview"
*</_int_month_>


** HOUSEHOLD IDENTIFICATION NUMBER
*<_idh_>
	egen idh=concat(psu hhold), punct(-)
	label var idh "Household id"
*</_idh_>


** INDIVIDUAL IDENTIFICATION NUMBER
*<_idp_>
	egen idp=concat(idh idp1), punct(-)
	label var idp "Individual id"
*</_idp_>


** HOUSEHOLD WEIGHTS
*<_wgt_>
	drop wgt
	gen double wgt=hhwgt
	label var wgt "Household sampling weight"
*</_wgt_>

	
** STRATA
*<_strata_>.
	egen strata=concat(year zilaid) 
	destring strata, replace
	label var strata "Strata"
	note strata: Stratum in HIES 2016 is different to previous years and has 132 strata. ///
	To compute means with standard errors and confidence intervals for all the ///
	available years we create a harmonized  stratum variable. Since stratum in ///
	2016 has 2 equal numbers (11,12) to stratum16 (2000, 2005, and 2010) we ///
	create a variable with 2016 before the stratum variable 2016 
*</_strata_>


** PSU
*<_psu_>
	*gen psu=PSU
	label var psu "Primary sampling units"
*</_psu_>

	
** MASTER VERSION
*<_vermast_>
	gen vermast="01"
	label var vermast "Master Version"
*</_vermast_>
	
	
** ALTERATION VERSION
*<_veralt_>
	gen veralt="01"
	label var veralt "Alteration Version"
*</_veralt_>	
	
	
/*****************************************************************************************************
*                                                                                                    *
                                   HOUSEHOLD CHARACTERISTICS MODULE
*                                                                                                    *
*****************************************************************************************************/


** LOCATION (URBAN/RURAL)
*<_urban_>
	gen byte urban=urbrural
	recode urban (1=0) (2=1)
	label var urban "Urban/Rural"
	la de lblurban 1 "Urban" 0 "Rural", replace
	label values urban lblurban
*</_urban_>
	

** REGIONAL AREAS

** REGIONAL AREA 1 DIGIT ADMN LEVEL
*<_subnatid1_>
	gen byte subnatid1=.
	replace subnatid1=div
	replace subnatid1=30 if subnatid1==45 & year==2016
	la de lblsubnatid1 10 "Barisal" 20 "Chittagong" 30 "Dhaka" 40 "Khulna" 50 "Rajshahi" 55 "Rangpur" 60 "Sylhet"
	label var subnatid1 "Region at 1 digit (ADMN1)"
	label values subnatid1 lblsubnatid1
	note subnatid1: Mymensingh Division was created in 2015 from districts previously comprising the northern part of Dhaka Division. We combine Mymensingh with Dhaka in this database
*</_subnatid1_>
	
		
** REGIONAL AREA 2 DIGIT ADMN LEVEL
*<_subnatid2_>
	gen byte subnatid2=zl
	label define lblsubnatid2 1 "Bagerhat", add
	label define lblsubnatid2 3 "Bandarban", add
	label define lblsubnatid2 4 "Barguna", add
	label define lblsubnatid2 6 "Barisal", add
	label define lblsubnatid2 9 "Bhola", add
	label define lblsubnatid2 10 "Bogra", add
	label define lblsubnatid2 12 "Brahmanbaria", add
	label define lblsubnatid2 13 "Chandpur", add
	label define lblsubnatid2 15 "Chittagong", add
	label define lblsubnatid2 18 "Chuadanga", add
	label define lblsubnatid2 19 "Comilla", add
	label define lblsubnatid2 22 "Cox's bazar", add
	label define lblsubnatid2 26 "Dhaka", add
	label define lblsubnatid2 27 "Dinajpur", add
	label define lblsubnatid2 29 "Faridpur", add
	label define lblsubnatid2 30 "Feni", add
	label define lblsubnatid2 32 "Gaibandha", add
	label define lblsubnatid2 33 "Gazipur", add
	label define lblsubnatid2 34 "Rajbari", add
	label define lblsubnatid2 35 "Gopalganj", add
	label define lblsubnatid2 36 "Habiganj", add
	label define lblsubnatid2 38 "Jaipurhat", add
	label define lblsubnatid2 39 "Jamalpur", add
	label define lblsubnatid2 41 "Jessore", add
	label define lblsubnatid2 42 "Jhalokati", add
	label define lblsubnatid2 44 "Jhenaidah", add
	label define lblsubnatid2 46 "Khagrachari", add
	label define lblsubnatid2 47 "Khulna", add
	label define lblsubnatid2 48 "Kishoreganj", add
	label define lblsubnatid2 49 "Kurigram", add
	label define lblsubnatid2 50 "Kushtia", add
	label define lblsubnatid2 51 "Lakshmipur", add
	label define lblsubnatid2 52 "Lalmonirhat", add
	label define lblsubnatid2 54 "Madaripur", add
	label define lblsubnatid2 55 "Magura", add
	label define lblsubnatid2 56 "Manikganj", add
	label define lblsubnatid2 57 "Meherpur", add
	label define lblsubnatid2 58 "Maulvibazar", add
	label define lblsubnatid2 59 "Munshigan", add
	label define lblsubnatid2 61 "Mymensingh", add
	label define lblsubnatid2 64 "Naogaon", add
	label define lblsubnatid2 65 "Narail", add
	label define lblsubnatid2 67 "Narayanganj", add
	label define lblsubnatid2 68 "Narsingdi", add
	label define lblsubnatid2 69 "Natore", add
	label define lblsubnatid2 70 "Nawabganj", add
	label define lblsubnatid2 72 "Netrokona", add
	label define lblsubnatid2 73 "Nilphamari", add
	label define lblsubnatid2 75 "Noakhali", add
	label define lblsubnatid2 76 "Pabna", add
	label define lblsubnatid2 77 "Panchagar", add
	label define lblsubnatid2 78 "Patuakhali", add
	label define lblsubnatid2 79 "Pirojpur", add
	label define lblsubnatid2 81 "Rajshahi", add
	label define lblsubnatid2 82 "Rajbari", add
	label define lblsubnatid2 84 "Rangamati", add
	label define lblsubnatid2 85 "Rangpur", add
	label define lblsubnatid2 86 "Shariatpur", add
	label define lblsubnatid2 87 "Satkhira", add
	label define lblsubnatid2 88 "Sirajganj", add
	label define lblsubnatid2 89 "Sherpur", add
	label define lblsubnatid2 90 "Sunamganj", add
	label define lblsubnatid2 91 "Sylhet", add
	label define lblsubnatid2 93 "Tangail", add
	label define lblsubnatid2 94 "Thakurgaon", add
	label var subnatid2 "Region at 2 digit (ADMN2)"
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
	gen byte ownhouse=.
	replace ownhouse=1 if s6aq23==1
	replace ownhouse=0 if s6aq23!=1 & s6aq23!=.
	replace ownhouse=. if s6aq23==5 
	note ownhouse: "BGD 2016" There is an extra categorie and it is classified as missing
	label var ownhouse "House ownership"
	la de lblownhouse 0 "No" 1 "Yes"
	label values ownhouse lblownhouse
*</_ownhouse_>


** TENURE OF DWELLING
*<_tenure_>
	gen tenure=.
	replace tenure=1 if s6aq23==1
	replace tenure=2 if s6aq23==2 
	replace tenure=3 if s6aq23==3 
	label var tenure "Tenure of Dwelling"
	la de lbltenure 1 "Owner" 2"Renter" 3"Other"
	la val tenure lbltenure
*</_tenure_>	


** LANDHOLDING
*<_lanholding_>
   gen landholding=  s7aq01>0 | s7aq02>0 | s7aq03>0 if !mi(s7aq01,s7aq02,s7aq03)
   label var landholding "Household owns any land"
   la de lbllandholding 0 "No" 1 "Yes"
   la val landholding lbllandholding
   note landholding: "BGD 2016" dummy activated if hh owns at least more than 0 decimals of any type of land (aggricultural, dwelling, non-productive).
*</_lanholding_>	


** ORIGINAL WATER CATEGORIES
*<_water_orig_>
	gen water_orig=s6aq12
	la var water_orig "Source of Drinking Water-Original from raw file"
	#delimit
	la def lblwater_orig 1 "Supply water"
						 2 "Tubewell"
						 3 "Pond/river"
						 4 "Well"
						 5 "Waterfall/string"
						 6 "Other";
	#delimit cr
	la val water_orig lblwater_orig
*</_water_orig_>


** PIPED SOURCE OF WATER
*<_piped_water_>
	gen piped_water= s6aq12==1 if s6aq12!=.
	la var piped_water "Household has access to piped water"
	la def lblpiped_water 1 "Yes" 0 "No"
	la val piped_water lblpiped_water
	note piped_water: "BGD 2016" note that "Supply water" category does not necessarily cover water supplied into dwelling. It may be tap water into compound or from public tap. ///
	See technical documentation from Water GP for further detail.
*</_piped_water_>


** INTERNATIONAL WATER COMPARISON (Joint Monitoring Program)
*<_water_jmp_>
	gen water_jmp=.
	replace water_jmp=1 if s6aq12==1
	replace water_jmp=4 if s6aq12==2
	replace water_jmp=12 if s6aq12==3
	replace water_jmp=14 if s6aq12==4
	replace water_jmp=14 if s6aq12==5
	replace water_jmp=14 if s6aq12==6

	label var water_jmp "Source of drinking water-using Joint Monitoring Program categories"
	#delimit
	la de lblwater_jmp 1 "Piped into dwelling" 	
					   2 "Piped into compound, yard or plot" 
					   3 "Public tap / standpipe" 
					   4 "Tubewell, Borehole" 
					   5 "Protected well"
					   6 "Unprotected well"
					   7 "Protected spring"
					   8 "Unprotected spring"
					   9 "Rain water"
					   10 "Tanker-truck or other vendor"
					   11 "Cart with small tank / drum"
					   12 "Surface water (river, stream, dam, lake, pond)"
					   13 "Bottled water"
					   14 "Other";
	#delimit cr
	la values  water_jmp lblwater_jmp
	note water_jmp: "BGD 2016" Categories "Well" and "Waterfall / Spring" are classified as other according to JMP definitions, given that this are ambigous categories. 
	note water_jmp: "BGD 2016" note that "Piped into dwelling" category does not necessarily cover water supplied into dwelling. It may be tap water into compound or from public tap. ///
	See technical documentation from Water GP for further detail.
*</_water_jmp_>


** SAR IMPROVED SOURCE OF DRINKING WATER
*<_sar_improved_water_>
	gen sar_improved_water=.
	replace sar_improved_water=1 if inlist(water_jmp,1,2,3,4,5,7,9)
	replace sar_improved_water=0 if inlist(water_jmp,6,8,10,11,12,13,14)
	la def lblsar_improved_water 1 "Improved" 0 "Unimproved"
	la var sar_improved_water "Improved source of drinking water-using country-specific definitions"
	la val sar_improved_water lblsar_improved_water
*</_sar_improved_water_>

	
** ELECTRICITY PUBLIC CONNECTION
*<_electricity_>
	recode s6aq17 (2=0) (3=.), gen (electricity)
	label var electricity "Electricity main source"
	la de lblelectricity 0 "No" 1 "Yes", replace
	label values electricity lblelectricity
*</_electricity_>


** ORIGINAL WATER CATEGORIES
*<_toilet_orig_>
	gen toilet_orig=s6aq10
	la var toilet_orig "Access to sanitation facility-Original from raw file"
	#delimit
	la def lbltoilet_orig 1 "Sanitary"
						  2 "Pacca latrine(Water seal)"
						  3 "Pacca latrine(Pit)"
						  4 "Kacha latrine (perm)"
						  5 "Kacha latrine (temp)"
						  6 "Other";
	#delimit cr
	la val toilet_orig lbltoilet_orig
*</_toilet_orig_>


** SEWAGE TOILET
*<_sewage_toilet_>
	gen sewage_toilet=s6aq10
	recode sewage_toilet  2/6=0
	la var sewage_toilet "Household has access to sewage toilet"
	la def lblsewage_toilet 1 "Yes" 0 "No"
	la val sewage_toilet lblsewage_toilet
*</_sewage_toilet_>


** INTERNATIONAL SANITATION COMPARISON (Joint Monitoring Program)
*<_toilet_jmp_>
	gen toilet_jmp=.
	label var toilet_jmp "Access to sanitation facility-using Joint Monitoring Program categories"
	#delimit 
	la def lbltoilet_jmp 1 "Flush to piped sewer  system"
						2 "Flush to septic tank"
						3 "Flush to pit latrine"
						4 "Flush to somewhere else"
						5 "Flush, don't know where"
						6 "Ventilated improved pit latrine"
						7 "Pit latrine with slab"
						8 "Pit latrine without slab/open pit"
						9 "Composting toilet"
						10 "Bucket toilet"
						11 "Hanging toilet/hanging latrine"
						12 "No facility/bush/field"
						13 "Other";
	#delimit cr
	la val toilet_jmp lbltoilet_jmp

	note toilet_jmp: "BGD 2016" Unlike previous rounds, category 'open field' from water_orig is not present for this round. ///
	In that sense, it is not possible to classify into any category water_jmp from water_orig. 
*</_toilet_jmp_>


** SAR IMPROVED TYPE OF TOILET 
*<_sar_improved_toilet_>
	gen sar_improved_toilet=.
	replace sar_improved_toilet=1 if inlist(s6aq10,1,2,3)
	replace sar_improved_toilet=0 if inlist(s6aq10,4,5,6)
	la def lblsar_improved_toilet 1 "Improved" 0 "Unimproved"
	la var sar_improved_toilet "Improved type of sanitation facility-using country-specific definitions"
	la val sar_improved_toilet lblsar_improved_toilet
*</_sar_improved_toilet_>
	
	
** LAND PHONE
*<_landphone_>
	recode s6aq19 (2=0) (3=.), gen(landphone)
	label var landphone "Phone availability"
	la de lbllandphone 0 "No" 1 "Yes"
	label values landphone lbllandphone
*</_landphone_>


** CELLPHONE
*<_cellphone_>
	recode s1aq10 (2=0), gen(cellphone) 
	label var cellphone "Cell phone"
	la de lblcellphone 0 "No" 1 "Yes"
	label values cellphone lblcellphone
*</_cellphone_>
	
	
** COMPUTER
*<_computer_>
	recode s6aq20 (2=0) (0=.), gen(computer)
	label var computer "Computer availability"
	la de lblcomputer 0 "No" 1 "Yes"
	label values computer lblcomputer
*</_computer_>


** INTERNET
*<_internet_>
	recode s6aq21 (2=0) (0=.), gen(internet)
	label var internet "Internet connection"
	la de lblinternet 0 "No" 1 "Yes"
	label values internet lblinternet
*<_internet_>


/*****************************************************************************************************
*                                                                                                    *
                                   DEMOGRAPHIC MODULE
*                                                                                                    *
*****************************************************************************************************/


** HOUSEHOLD SIZE
*<_hsize_>
	ren member hsize
	label var hsize "Household size"
*</_hsize_>


** POPULATION WEIGHT
*<_pop_wgt_>
	gen pop_wgt=wgt*hsize
	la var pop_wgt "Population weight"
*</_pop_wgt_>


** RELATIONSHIP TO THE HEAD OF HOUSEHOLD
*<_relationharm_>

	*Head of household corrected variable provided by the Bangladesh team
	
	**********************Correction to household head variable*********************

	*Members of household
	bys hhold: egen member=count(idp1)

	*Household heads
	replace s1aq02=. if s1aq02==0
	replace s1aq02=14 if s1aq02==. & hhold==387041 & idp1==2

	gen head=(s1aq02==1) if s1aq02!=.
	bys hhold: egen heads=total(head) 
	replace heads=. if head==.

	egen hh=tag(hhold)
	tab heads if hh==1

	*Maximum age inside the household
	bys hhold: egen maxage=max(s1aq03)
	gen oldest=(s1aq03==maxage)

	*Highest age of males in the household
	bys hhold: egen maxageman=max(s1aq03) if s1aq01==1
	gen oldestman=(s1aq03==maxageman)

	*Household head is male married
	gen menmarriedhh= (s1aq01==1 & s1aq02==1 & s1aq05==1) 
	bys hhold: egen menmarriedhht=total(menmarriedhh)

	*Male married
	gen malemarried=(s1aq05==1 & s1aq01==1)
	bys hhold: egen malemarriedt=total(malemarried) if s1aq01!=.

	*Household head is female
	gen femalehh=(s1aq01==2 & s1aq02==1)
	bys hhold: egen femalehht=total(femalehh)

	*Are there any households in our sample that have a male in the household that is older than the married male household head? 
	gen aux=1 if oldestman==1 & head==0 & menmarriedhht==1 & femalehht==0
	bys hhold: egen auxt=total(aux) 
	tab auxt if hh==1
	tab s1aq02 if inlist(auxt,1) & oldest==1

	*Count number of males in the household
	gen men= (s1aq01==1) if s1aq01!=.
	bys hhold: egen ment=total(men) if s1aq01!=.

	*Female is the oldest member in the household
	gen oldestisfemale=(s1aq03==maxage & s1aq01==2)
	bys hhold: egen oldestisfemalet=total(oldestisfemale)

	*Males aged 16 years and above
	gen young=(s1aq03>15 & s1aq01==1)
	bys hhold: egen youngt=total(young)

	****************Apply rules to correct household head***************************

	*Create the new household head variable
	gen p=.
	gen headnew=.
	replace headnew=1 if head==1 & heads==1

	*1. Households with only one member and they have zero household head 
	replace p=1 if heads==0 & member==1 
	bys hhold: egen heads2=total(p)
	tab heads2 if hh==1
	replace headnew=p if heads2==1
	replace heads=heads2 if heads2==1
	tab heads if hh==1

	*2. Highest age and male married
	cap drop heads2
	replace p=.
	replace p=1 if inlist(heads,0,2,3,4,6) & oldest==1  &  malemarried==1  
	bys hhold: egen heads2=total(p)
	tab heads2 if hh==1
	replace headnew=p if heads2==1
	replace heads=heads2 if heads2==1
	tab heads if hh==1

	*3. Male married
	cap drop heads2
	replace p=.
	replace p=1 if inlist(heads,0,2,3,4,6) & malemarried==1 
	bys hhold: egen heads2=total(p)
	tab heads2 if hh==1
	replace headnew=p if heads2==1
	replace heads=heads2 if heads2==1
	tab heads if hh==1

	*4. Among males in the household the one with highest age if a female is not the oldest member in the household
	cap drop heads2
	replace p=.
	replace p=1 if inlist(heads,0,2,3,4,6) & oldestman==1 & oldestisfemalet==0
	bys hhold: egen heads2=total(p)
	tab heads2 if hh==1
	replace headnew=p if heads2==1
	replace heads=heads2 if heads2==1
	tab heads if hh==1

	*5. Female with highest age and zero males aged 16 years and above in the household
	cap drop heads2
	replace p=.
	replace p=1 if inlist(heads,0,2,3,4,6) & oldest==1 & s1aq01==2 & youngt==0
	bys hhold: egen heads2=total(p)
	tab heads2 if hh==1
	replace headnew=p if heads2==1
	replace heads=heads2 if heads2==1
	tab heads if hh==1

	*6. Male with highest age
	cap drop heads2
	replace p=.
	replace p=1 if inlist(heads,0,2,3,4,6) & oldestman==1
	bys hhold: egen heads2=total(p)
	tab heads2 if hh==1
	replace headnew=p if heads2==1
	replace heads=heads2 if heads2==1
	tab heads if hh==1

	*1 household without information to indentify the household head
	replace headnew=. if heads==0

	*Correct relationship of members with the head of household variable
	replace headnew=0 if headnew==. & s1aq02!=.
	replace  s1aq02=14 if headnew==0 & s1aq02==1
	replace s1aq02=1 if headnew==1

	gen byte relationharm=s1aq02
	recode relationharm  (6=4) (4 5 7 8 9 10 11=5) (12 13 14 = 6) (0=.)
	label var relationharm "Relationship to the head of household"
	la de lblrelationharm  1 "Head of household" 2 "Spouse" 3 "Children" 4 "Parents" 5 "Other relatives" 6 "Non-relatives"
	label values relationharm  lblrelationharm
*</_relationharm_>


** RELATIONSHIP TO THE HEAD OF HOUSEHOLD (ORIGINAL SURVEY VARIABLE)
*<_relationcs_>
	gen byte relationcs=s1aq02
	replace relationcs=. if s1aq02==0
	la var relationcs "Relationship to the head of household country/region specific"
	label define lblrelationcs 1 "Head" 2 "Husband/Wife" 3 "Son/Daughter" 4 "Spouse of Son/Daughter" 5 "Grandchild" 6 "Father/Mother" 7 "Brother/Sister" 8 "Niece/Nephew" 9 "Father/Mother-in-law" 10 "Brother/Sister-in-law" 11 "Other relative" 12 "Servant" 13 "Employee" 14 "Other"
	label values relationcs lblrelationcs
*</_relationcs_>


** GENDER
*<_male_>
	gen byte male= s1aq01
	recode male (2=0)
	label var male "Sex of household member"
	la de lblmale 1 "Male" 0 "Female"
	label values male lblmale
*</_male_>


** AGE
*<_age_>
	gen byte age= s1aq03
	replace age=98 if age>98 & s1aq03!=.
	label var age "Age of individual"
*</_age_>


** SOCIAL GROUP
*<_soc_>
	gen byte soc=s1aq04
	label var soc "Social group"
	la de lblsoc 1 "Islam" 2 "Hinduism" 3 "Buddhism" 4 "Christianity" 5 "Other"
	label values soc lblsoc
*</_soc_>


** MARITAL STATUS
*<_marital_>
	gen byte marital=.
	replace marital=1 if s1aq05==1
	replace marital=4 if s1aq05==5 | s1aq05==4
	replace marital=5 if s1aq05==3
	replace marital=2 if s1aq05==2
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
	gen byte atschool=s2bq01
	replace atschool=0 if s2bq01==2
	replace atschool=. if s2bq01>2
	replace atschool=. if age<5
	
	label var atschool "Attending school"
	la de lblatschool 0 "No" 1 "Yes"
	label values atschool  lblatschool
*</_atschool_>


** CAN READ AND WRITE
*<_literacy_>
	gen byte literacy=.
	replace literacy=1 if s2aq01==1 & s2aq02==1
	replace literacy=0 if (s2aq01==2 | s2aq02==2) & literacy!=1 /* A person with different response is reported as missing */
	replace literacy=. if age<ed_mod_age
	*Values that don't correspond to the survey options are send to missing
	replace literacy=. if (s2aq01!=1 & s2aq01!=2) | (s2aq02!=2 & s2aq02!=1)
	label var literacy "Can read & write"
	la de lblliteracy 0 "No" 1 "Yes", replace
	label values literacy lblliteracy
*</_literacy_>


** YEARS OF EDUCATION COMPLETED
*<_educy_>
	gen educy=s2aq04
	recode educy (11=12) (15=16) (18=18) (16=19) (17=17) (12=14) (14=14) (13=16) (19=.) (21=.)
	replace educy=s2bq03 if educy==. & s2bq03!=.
	*Substract one year of education to those currently studying before secondary
	replace educy=educy-1 if s2aq04==. & s2bq03<=11 & s2bq03!=.
	*Substract one year of education to those currently studying after secondary
	recode educy (10=11) (15=15) (18=17) (16=18) (17=16) (12=13) (14=13) (13=15) (19=.) (21=.) if s2aq04==. & s2bq03!=.
	replace educy=0 if educy==-1
	replace educy=. if educy==50
	replace educy=. if age<5
	replace educy=. if educy>age & educy!=. & age!=.
	label var educy "Years of education"
	/*check: https://www.winona.edu/socialwork/Media/Prodhan%20The%20Educational%20System%20in%20Bangladesh%20and%20Scope%20for%20Improvement.pdf*/
*</_educy_>


** EDUCATION LEVEL 7 CATEGORIES
*<_educat7_>
	gen byte educat7=.
	replace educat7=1 if educy==0
	replace educat7=2 if (educy>0 & educy<5)
	replace educat7=3 if (educy==5)
	replace educat7=4 if (educy>5 & educy<12)
	replace educat7=5 if (educy==12)
	replace educat7=7 if (educy>12 & educy<23)
	replace educat7=6 if inlist(educy,13,14)
	replace educat7=8 if s2aq04==19 | s2bq03==19
	replace educat7=. if age<5
	label define lbleducat7 1 "No education" 2 "Primary incomplete" 3 "Primary complete" ///
	4 "Secondary incomplete" 5 "Secondary complete" 6 "Higher than secondary but not university" /// 
	7 "University incomplete or complete" 8 "Other" 9 "Not classified"
	label values educat7 lbleducat7
	la var educat7 "Level of education 7 categories"
*</_educat7_>


** EDUCATION LEVEL 4 CATEGORIES
*<_educat4_>
	gen byte educat4=.
	replace educat4=1 if educat7==1 
	replace educat4=2 if educat7==2 |educat7==3
	replace educat4=3 if educat7==4 |educat7==5
	replace educat4=4 if educat7==6 |educat7==7
	label var educat4 "Level of education 4 categories"
	label define lbleducat4 1 "No education" 2 "Primary (complete or incomplete)" ///
	3 "Secondary (complete or incomplete)" 4 "Tertiary (complete or incomplete)"
	label values educat4 lbleducat4
*</_educat4_>

	
** EDUCATION LEVEL 5 CATEGORIES
*<_educat5_>
	gen educat5=.
	replace educat5=1 if educat7==1
	replace educat5=2 if educat7==2
	replace educat5=3 if educat7==3 | educat7==4
	replace educat5=4 if educat7==5
	replace educat5=5 if educat7==6 |educat7==7
	label define lbleducat5 1 "No education" 2 "Primary incomplete" ///
	3 "Primary complete but secondary incomplete" 4 "Secondary complete" ///
	5 "Some tertiary/post-secondary"
	label values educat5 lbleducat5
	la var educat5 "Level of education 5 categories"
*</_educat5_>


** EVER ATTENDED SCHOOL
*<_everattend_>
	gen byte everattend=.
	replace everattend=0 if educat7==1 
	replace everattend=1 if (educat7>=2 & educat7!=.) | atschool==1
	replace everattend=. if age<5
	label var everattend "Ever attended school"
	la de lbleverattend 0 "No" 1 "Yes"
	label values everattend lbleverattend
*</_everattend_>

	replace educy=0 if everattend==0
	replace educat7=1 if everattend==0
	replace educat4=1 if everattend==0
	replace educat5=1 if everattend==0
	
foreach var in atschool literacy educy everattend educat4 educat5 educat7 {

	replace `var'=. if age<ed_mod_age

}

/*****************************************************************************************************
*                                                                                                    *
                                   LABOR MODULE
*                                                                                                    *
*****************************************************************************************************/


** LABOR MODULE AGE
*<_lb_mod_age_>
	gen byte lb_mod_age=5
	label var lb_mod_age "Labor module application age"
*</_lb_mod_age_>


** LABOR STATUS
*<_lstatus_>
	gen byte lstatus=.
	replace lstatus=1 if s1bq01==1
	replace lstatus=2 if s1bq01==2 & s1bq03==1 
	replace lstatus=3 if s1bq01==2 & (s1bq02==2 | s1bq03==2)
	replace lstatus=2 if s1bq04==8 | s1bq04==10 /*Waiting to start new job /and/ On leave/looking for job/business*/
	replace lstatus=3 if s1bq04!=. & s1bq01==2 & lstatus==.
	replace lstatus=. if age<5
	label var lstatus "Labor status"
	la de lbllstatus 1 "Employed" 2 "Unemployed" 3 "Non-LF"
	label values lstatus lbllstatus
	notes lstatus: "BGD 2016" a person is considered "unemployed" if not working but waiting to start a new job.
	notes lstatus: "BGD 2016" question related to available to accept a job is not taken into account in the definition of unemployed.
*</_lstatus_>


/** LABOR STATUS LAST YEAR
*<_lstatus_year_>
	gen byte lstatus_year=1 if (s04a_q021>0 & s04a_q021<=12) | (s04a_q022>0 & s04a_q022<=12)
	replace lstatus_year=0 if s04a_q_11==""
	replace lstatus_year=. if age<lb_mod_age & age!=.
	label var lstatus_year "Labor status during last year"
	la de lbllstatus_year 1 "Employed" 0 "Not employed" 
	label values lstatus_year lbllstatus_year
*</_lstatus_year_>*/


** EMPLOYMENT STATUS
*<_empstat_>
	gen byte empstat=.
	replace empstat=1 if s4aq07==1|s4aq08==1|s4aq07==4|s4aq08==4
	replace empstat=3 if s4aq07==3| s4aq08==3
	replace empstat=4 if s4aq07==2| s4aq08==2
	replace empstat=. if lstatus!=1
	label var empstat "Employment status"
	la de lblempstat 1 "Paid employee" 2 "Non-paid employee" 3 "Employer" 4 "Self-employed" 5 "Other"
	label values empstat lblempstat
*</_empstat_>


/** EMPLOYMENT STATUS LAST YEAR
*<_empstat_year_>
	gen byte empstat_year=empstat
	replace empstat_year=. if lstatus_year!=1
	label var empstat_year "Employment status during last year"
	la de lblempstat_year 1 "Paid employee" 2 "Non-paid employee" 3 "Employer" 4 "Self-employed" 5 "Other, workers not classifiable by status"
	label values empstat_year lblempstat_year
*</_empstat_year_>*/


** NUMBER OF ADDITIONAL JOBS 
*<_njobs_>
	label var njobs "Number of additional jobs"
	replace njobs=. if lstatus!=1
*</_njobs_>


/** NUMBER OF ADDITIONAL JOBS LAST YEAR
*<_njobs_year_>
	gen byte njobs_year=njobs
	replace njobs_year=. if lstatus_year!=1
	label var njobs_year "Number of additional jobs during last year"
*</_njobs_year_>*/


** SECTOR OF ACTIVITY: PUBLIC - PRIVATE
*<_ocusec_>
	gen byte ocusec=.
	replace ocusec= 1 if s4bq06==1 | s4bq06==2 | s4bq06==4 | s4bq06==6
	replace ocusec= 1 if s4bq06==7
	replace ocusec= 2 if s4bq06==3 | s4bq06==5 | s4bq06==8
	replace ocusec=. if lstatus!=1
	label var ocusec "Sector of activity"
	la de lblocusec 1 "Public, state owned, government, army, NGO" 2 "Private", replace
	label values ocusec lblocusec
*</_ocusec_>


** REASONS NOT IN THE LABOR FORCE
*<_nlfreason_>
	gen byte nlfreason=. 
	replace nlfreason=1 if s1bq04==3
	replace nlfreason=2 if s1bq04==2 | s1bq04==1
	replace nlfreason=3 if s1bq04==4
	replace nlfreason=4 if s1bq04==7
	replace nlfreason=5 if s1bq04==5 | s1bq04==6 | s1bq04>=9 & s1bq04<=11
	replace nlfreason=. if s1bq04==0 | s1bq04==14 | lstatus!=3

	label var nlfreason "Reason not in the labor force"
	la de lblnlfreason 1 "Student" 2 "Housewife" 3 "Retired" 4 "Disable" 5 "Other"
	label values nlfreason lblnlfreason
*</_nlfreason_>


** UNEMPLOYMENT DURATION: MONTHS LOOKING FOR A JOB
*<_unempldur_l_>
	gen byte unempldur_l=.
	label var unempldur_l "Unemployment duration (months) lower bracket"
*</_unempldur_l_>


*<_unempldur_u_>
	gen byte unempldur_u=.
	label var unempldur_u "Unemployment duration (months) upper bracket"
*</_unempldur_u_>


** ORIGINAL INDUSTRY CLASSIFICATION
*<_industry_orig_>
gen industry_orig=s4aq01c
#delimit
la def lblindustry_orig
	1	"Agriculture, hunting and relating activities"
	2	"Forestry and forest-related activities"
	5	"Fishing and fish-related activities"
	10	"Minerals (coal)"
	11	"Gas and oil exploration"
	14	"Other Mineral Exploration"
	15	"Food and water production"
	16	"Production of tobacco products"
	17	"Clothing Manufacturing"
	18	"Garment production, bleached and dyed"
	19	"production of leather and leather related Goods"
	20	"Manufacture of Wood and wood products, except furniture"
	21	"Manufacture of paper and paper products"
	22	"Publishing, Printing and Recording"
	23	"Petroleum refining"
	24	"Production of chemicals"
	25	"Rubber and plastic products"
	26	"Production of other non-metallic mineral products"
	27	"Metal Manufacturing"
	28	"Production of metal products, except machinery"
	29	"Other unclassified Electronics Manufacturing"
	30	"Production of Machinery used in office and accounting"
	31	"Production of electrical equipment"
	32	"Production of Radio, television and media equipment"
	33	"Watch, glasses and medical equipment manufacturing"
	34	"Car production"
	35	"Machinery used in the production of other vehicles"
	36	"Production of furniture and unclassified"
	37	"Re-Processing"
	40	"Gas, hot water and electricity supply"
	41	"Water collection, purification and supply"
	45	"Construction"
	50	"Car and motorcycle sales, maintenance, repair and fuel sales"
	51	"Other than the business of car and motorcycle"
	52	"Car and motorcycle business and personal home use goods other than retail"
	55	"Hotel and Restaurant"
	60	"Road vehicles"
	61	"Shipping Vehicle"
	62	"Aircraft"
	63	"Travel assistance (Transport and Travel Agencies)"
	64	"Post and Telecommunications"
	65	"Financial intermediation, except insurance and pension"
	66	"Insurance and pension"
	67	"Helping financial mediation"
	70	"Real State"
	71	"Personal and home used to hire equipment"
	72	"Computer and Computer related working"
	73	"Research and development"
	74	"Other business"
	75	"Public administration, defense and compulsory social security"
	80	"Education"
	81	"Health & Social Services"
	90	"Drainage and sewerage type of work"
	92	"Entertainment, cultural and sports-related work"
	99	"Foreign Agencies";
#delimit cr
destring industry_orig, replace
la val industry_orig  lblindustry_orig
replace industry_orig=. if lstatus!=1

#delimit

recode industry_orig (0 3 4 6 7 8 9 12 13 39 42 43
 44 46 47 49 53 54 56 57 58 59 76 77 78 79 82 83 84
 85 86 87 91 94 96=.) /*Incorrect codes are send to missing*/;
 
#delimit cr
la var industry_orig "Original industry code"
*</_industry_orig_>


** INDUSTRY CLASSIFICATION
*<_industry_>
	gen industry=industry_orig
	destring industry,replace
	recode industry (0=.) (1/5=1) (10/14=2) (15/39=3) (40/43=4) (45/49=5) (50/59=6) (60/64=7) (65/74=8) (75=9) (76/99=10) (nonmis=.)
	replace industry=. if lstatus==2| lstatus==3
	label var industry "1 digit industry classification"
	replace industry=. if lstatus!=1
	la de lblindustry 1 "Agriculture" 2 "Mining" 3 "Manufacturing" 4 "Public utilities" 5 "Construction"  6 "Commerce" 7 "Transport and Comnunications" 8 "Financial and Business Services" 9 "Public Administration" 10 "Other Services, Unspecified"
	label values industry lblindustry
*</_industry_>


**ORIGINAL OCCUPATION CLASSIFICATION
*<_occup_orig_>
gen occup_orig=s4aq01b
#delimit
	la def lbloccup_orig
	1	"Physical Scientists and Related Technician"
	2	"Architects and Engineers"
	3	"Architects, Engineers and Related Technicians"
	4	"Air craft and ships officers"
	5	"Life Scientists and Related Technicians"
	6	"Medical, Dental and Veterinary surgeons"
	7	"Professional Nurse and Related Workers"
	8	"Statistician, Mathematicians, Systems Analyst and Related Workers"
	9	"Economist"
	10	"Accountants"
	12	"Jurists"
	13	"Teachers"
	14	"Workers and Religion"
	15	"Authors, Journalists and Related Writers"
	16	"Fine and Commercial Artists, Photographers and Related Creative Artists"
	17	"Actor, Singer and Dancers"
	18	"Sportsman and Related Workers"
	19	"Professional, Technical and Related Workers and Not Elsewhere Classified"
	20	"Lower"
	21	"Manager"
	30	"Government Executive Officer"
	31	"Clerical"
	32	"Typist, Stenographers"
	33	"Book-Keepers, Cashier and Related Workers"
	34	"Computer and Related Workers"
	35	"Transport and Communication Supervisor"
	36	"Driver, Conductors"
	37	"Mail Distribution Clerks"
	38	"Telephone and Telegraph Operators"
	39	"Clerical and Related Workers N.E.C"
	40	"Manager (Wholesale and Retail Trade)"
	42	"Sales Supervisors and Buyer"
	43	"Travelers and Related Workers"
	44	"Insurance, Real Estate, Business and Related Services Sales-man"
	45	"Street Vendors"
	49	"Salesmen Not Elsewhere Classified"
	50	"Residential Hotel Manager"
	51	"Working Proprietors (Catering and Lodging Services)"
	52	"Supervisor Catering and Lodging Services"
	53	"Cooks, Waiters and Related Workers"
	54	"Maids and Related Housekeeping Services Workers Not Elsewhere Classified"
	55	"Building Caretakers, Cleaners and Related Workers"
	56	"Launderers, Dry-Cleaners and Pressers"
	58	"Protective Service Workers"
	59	"Service Workers Not Elsewhere Classified"
	60	"Farm Manager and Supervisors"
	61	"Farmers"
	63	"Forestry Workers"
	64	"Fisherman, Hunts and Related Workers"
	70	"Production Supervisors and General Foreman"
	71	"Miners, Quarrymen, Well Drillers and Related Workers"
	72	"Metal Processors"
	74	"Chemical Processors and Related Workers"
	75	"Spinners, Weavers, Knitters, Dyers and Related Textile Workers"
	76	"Tanners, Fellmongers and Pelt Dressers"
	77	"Food and Beverage Processors"
	78	"Tobacco Preparers and Cigarette Makers"
	79	"Tailors, Dressmakers, Sewers, Upholsterers and Related Workers"
	80	"Shoemakers and Leather Goods Makers"
	81	"Cabinetmakers and Related Wood Workers"
	82	"Stone Cutter and Finishers"
	83	"Forging Workers, Toolmakers and Metalworking Machine Operator"
	84	"Machinery Fitters, Machinery Mechanics and Precision Instrument Makers"
	85	"Electric Worker"
	86	"Broadcast and Sound Equipment Operators and Motion Picture Projectionist"
	87	"Plumbers, Welders and Sheet Metal and Structural Metal Workers"
	88	"Jewellery and Precious Metal Workers"
	89	"Glass Foreman, Potters and Related Workers"
	90	"Rubber and Plastics Product Makers"
	91	"Paper and Paperboard Products Makers"
	92	"Printing";
	
#delimit cr

	destring occup_orig, replace
	la val occup_orig lbloccup_orig
	replace occup_orig=. if lstatus!=1

#delimit

recode occup_orig (11 22 25 26 41 46 47 48 57 62 65 67 69 93 96 99
 0=.) /*Incorrect codes are send to missing*/;
 
#delimit cr

	la var occup_orig "Original occupation code"
*</_occup_orig_>


** OCCUPATION CLASSIFICATION
*<_occup_>
#delimit
recode s4aq01b (1=3)	(2=2)	(3=3)	(4=2)	(5=3)	(6=2)	(40=1)	(8=2)	(9=2)	(10=2)	(12=2)	(13=2)	(14=3)	(15=2)	
(16=2)	(17=2)	(18=2)	(19=2)	(20=1)	(21=1)	(30=1)	(31=4)	(32=4)	(33=4)	(34=8)	(35=8)	(50=1)	(7=2)	(42=3)	(39=4)	(43=3)
	(44=3)	(86=3)	(37=4)	(38=4)	(36=5)	(45=5)	(51=5)	(52=5)	(53=5)	(54=5)	(49=5)	(70=6)	(58=5)	(59=5)	(60=6)	(61=6)	(63=6)
	(64=6)	(71=7)	(72=7)	(75=7)	(74=8)	(76=7)	(77=7)	(78=7)	(79=7)	(80=7)	(81=7)	(82=7)	(83=7)	(84=7)	(85=7)	(87=7)	(88=7)
	(89=7)	(92=7)	(90=8)	(91=8)	(55=9)	(56=9) (11 22 25 26 41 46 47 48 57 62 65 67 69 93 96 99
	0 68 73=.) (nonmis=.), gen(occup);
	#delimit cr
	replace occup=. if lstatus!=1
	label var occup "1 digit occupational classification"
	la de lbloccup 1 "Senior officials" 2 "Professionals" 3 "Technicians" 4 "Clerks" 5 "Service and market sales workers" 6 "Skilled agricultural" 7 "Craft workers" 8 "Machine operators" 9 "Elementary occupations" 10 "Armed forces"  99 "Others"
	label values occup lbloccup
*</_occup_>


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
	/*There are some cases of people working more than 24 hours per day. They are classified as missing*/
	replace s4aq04=. if s4aq04>24
	gen whours=int(s4aq03* s4aq04)/4.25
	replace whours=. if lstatus!=1
	label var whours "Hours of work in last week"
*</_whours_>


/** WAGES
*<_wage_>
	gen double wage=.
	replace wage=s4bq07 if s4bq01==2
	replace wage=s4bq02c if s4bq01==1
	replace wage=0 if empstat==2
	replace wage=. if lstatus!=1
	label var wage "Last wage payment"
*</_wage_>*/


** WAGES TIME UNIT
*<_unitwage_>
	gen byte unitwage=.
	replace unitwage=1 if s4bq01==1 & wage!=.
	replace unitwage=5 if s4bq01==2 & wage!=.
	replace unitwage=. if lstatus!=1 
	replace unitwage=0 if empstat==2
	label var unitwage "Last wages time unit"
	la de lblunitwage 1 "Daily" 2 "Weekly" 3 "Every two weeks" 4 "Bimonthly"  5 "Monthly" 6 "Quarterly" 7 "Biannual" 8 "Annually" 9 "Hourly" 10 "Other"
	label values unitwage lblunitwage
*</_wageunit_>


/** EMPLOYMENT STATUS - SECOND JOB
*<_empstat_2_>
	gen byte empstat_2=.
	replace empstat_2=1 if s04a_q072==1|s04a_q082==1|s04a_q072==4|s04a_q082==4
	replace empstat_2=3 if s04a_q072==3| s04a_q082==3
	replace empstat_2=4 if s04a_q072==2| s04a_q082==2
	replace empstat_2=. if njobs==0 | njobs==. | lstatus!=1
	label var empstat_2 "Employment status - second job"
	la de lblempstat_2 1 "Paid employee" 2 "Non-paid employee" 3 "Employer" 4 "Self-employed" 5 "Other, workers not classifiable by status"
	label values empstat_2 lblempstat_2
*</_empstat_2_>


** EMPLOYMENT STATUS - SECOND JOB LAST YEAR
*<_empstat_2_year_>
	gen empstat_2_year=.
	replace empstat_2_year=empstat_2
	replace empstat_2_year=. if njobs_year==0 | njobs_year==. | lstatus_year!=1
	label var empstat_2_year "Employment status - second job last year"
	la de lblempstat_2_year 1 "Paid employee" 2 "Non-paid employee" 3 "Employer" 4 "Self-employed" 5 "Other, workers not classifiable by status"
	label values empstat_2_year lblempstat_2
*</_empstat_2_>


** INDUSTRY CLASSIFICATION - SECOND JOB
*<_industry_2_>
	gen industry_2=s04a_q_22
	destring industry_2,replace
	recode industry_2 (0=.) (1/5=1) (10/14=2) (15/39=3) (40/43=4) (45/49=5) (50/59=6) (60/64=7) (65/74=8) (75=9) (76/99=10)
	replace industry_2=. if njobs==0 | njobs==. | lstatus!=1
	label var industry_2 "1 digit industry classification - second job"
	la de lblindustry_2 1 "Agriculture" 2 "Mining" 3 "Manufacturing" 4 "Public utilities" 5 "Construction"  6 "Commerce" 7 "Transport and Comnunications" 8 "Financial and Business Services" 9 "Public Administration" 10 "Other Services, Unspecified"
	label values industry_2 lblindustry_2
*<_industry_2_>


**SURVEY SPECIFIC INDUSTRY CLASSIFICATION - SECOND JOB
*<_industry_orig_2_>
	gen industry_orig_2=s04a_q_22
	destring industry_orig_2, replace
	replace industry_orig_2=. if njobs==0 | njobs==. | lstatus!=1
	label var industry_orig_2 "Original Industry Codes - Second job"
	la de lblindustry_orig_2 1""
	label values industry_orig_2 lblindustry_orig
*</_industry_orig_2>


** OCCUPATION CLASSIFICATION - SECOND JOB
*<_occup_2_>
	destring s04a_q_12,replace
#delimit
recode s04a_q_12 (1=3)	(2=2)	(3=3)	(4=2)	(5=3)	(6=2)	(40=1)	(8=2)	(9=2)	(10=2)	(12=2)	(13=2)	(14=3)	(15=2)	
(16=2)	(17=2)	(18=2)	(19=2)	(20=1)	(21=1)	(30=1)	(31=4)	(32=4)	(33=4)	(34=8)	(35=8)	(50=1)	(7=2)	(42=3)	(39=4)	(43=3)
	(44=3)	(86=3)	(37=4)	(38=4)	(36=5)	(45=5)	(51=5)	(52=5)	(53=5)	(54=5)	(49=5)	(70=6)	(58=5)	(59=5)	(60=6)	(61=6)	(63=6)
	(64=6)	(71=7)	(72=7)	(75=7)	(74=8)	(76=7)	(77=7)	(78=7)	(79=7)	(80=7)	(81=7)	(82=7)	(83=7)	(84=7)	(85=7)	(87=7)	(88=7)
	(89=7)	(92=7)	(90=8)	(91=8)	(55=9)	(56=9) (0 46 47 62 65 68 73 99 41=.), gen(occup_2);
	#delimit cr
	replace occup_2=. if njobs==0 | njobs==. | lstatus!=1
	label var occup_2 "1 digit occupational classification - second job"
	la de lbloccup_2 1 "Senior officials" 2 "Professionals" 3 "Technicians" 4 "Clerks" 5 "Service and market sales workers" 6 "Skilled agricultural" 7 "Craft workers" 8 "Machine operators" 9 "Elementary occupations" 10 "Armed forces"  99 "Others"
	label values occup_2 lbloccup_2
*</_occup_2_>


** WAGES - SECOND JOB
*<_wage_2_>
	gen double wage_2=.
	replace wage_2=s04b_q_22 if s04b_q012==1
	replace wage_2=s04b_q082 if s04b_q012==2
	replace wage_2=0 if empstat_2==2
	replace wage_2=. if njobs==0 | njobs==. | lstatus!=1
	label var wage_2 "Last wage payment - Second job"
*</_wage_2_>


** WAGES TIME UNIT - SECOND JOB
*<_unitwage_2_>
	gen byte unitwage_2=.
	replace unitwage_2=1 if s04b_q012==1 &  wage_2!=.
	replace unitwage_2=5 if s04b_q012==2 & wage_2!=.
	replace unitwage_2=. if njobs==0 | njobs==. | lstatus!=1
	label var unitwage_2 "Last wages time unit - Second job"
	la de lblunitwage_2 1 "Daily" 2 "Weekly" 3 "Every two weeks" 4 "Every two months"  5 "Monthly" 6 "Quarterly" 7 "Every six months" 8 "Annually" 9 "Hourly" 10 "Other"
	label values unitwage_2 lblunitwage_2
*</_unitwage_2_>*/


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

#delimit

foreach var in lstatus /*lstatus_year*/ empstat /*empstat_year*/ /*njobs_year*/ ocusec 
 nlfreason unempldur_l unempldur_u industry_orig industry occup_orig occup 
 firmsize_l firmsize_u whours /*wage*/ unitwage /*empstat_2 empstat_2_year industry_2 
 industry_orig_2 occup_2 wage_2 unitwage_2*/ contract healthins socialsec union {;
 
	replace `var'=. if age<lb_mod_age;
	
};

#delimit cr

/*****************************************************************************************************
*                                                                                                    *
                                   MIGRATION MODULE
*                                                                                                    *
*****************************************************************************************************/


** REGION OF BIRTH JURISDICTION
*<_rbirth_juris_>
	gen byte rbirth_juris=.
	label var rbirth_juris "Region of birth jurisdiction"
	la de lblrbirth_juris 1 "subnatid1" 2 "subnatid2" 3 "subnatid3" 4 "Other country"  9 "Other code"
	label values rbirth_juris lblrbirth_juris
*</_rbirth_juris_>


** REGION OF BIRTH
*<_rbirth_>
	gen byte rbirth=.
	label var rbirth "Region of Birth"
*</_rbirth_>


** REGION OF PREVIOUS RESIDENCE JURISDICTION
*<_rprevious_juris_>
	gen byte rprevious_juris=.
	label var rprevious_juris "Region of previous residence jurisdiction"
	la de lblrprevious_juris 1 "reg01" 2 "reg02" 3 "reg03" 4 "Other country"  9 "Other code"
	label values rprevious_juris lblrprevious_juris
*</_rprevious_juris_>


** REGION OF PREVIOUS RESIDENCE
*<_rprevious_>
	gen byte rprevious=.
	label var rprevious "Region of previous residence"
*</_rprevious_>


** YEAR OF MOST RECENT MOVE
*<_yrmove_>
	gen int yrmove=.
	label var yrmove "Year of most recent move"
*</_yrmove_>


/*****************************************************************************************************
*                                                                                                    *
                                            ASSETS 
*                                                                                                    *
*****************************************************************************************************/


** RADIO
*<_radio_>
	gen radio=assets571
	label var radio "Household has radio"
	la de lblradio 0 "No" 1 "Yes"
	label val radio lblradio
*</_radio_>


** TELEVISION
*<_television_>
	gen television= assets582
	label var television "Household has Television"
	la de lbltelevision 0 "No" 1 "Yes"
	label val television lbltelevision
*</_television>


** FAN
*<_fan_>
	gen fan=  assets579
	label var fan "Household has Fan"
	la de lblfan 0 "No" 1 "Yes"
	label val fan lblfan
*</_fan>


** SEWING MACHINE
*<_sewingmachine_>
	gen sewingmachine= assets586
	label var sewingmachine "Household has Sewing machine"
	la de lblsewingmachine 0 "No" 1 "Yes"
	label val sewingmachine lblsewingmachine
*</_sewingmachine>


** WASHING MACHINE
*<_washingmachine_>
	gen washingmachine= assets578
	label var washingmachine "Household has Washing machine"
	la de lblwashingmachine 0 "No" 1 "Yes"
	label val washingmachine lblwashingmachine
*</_washingmachine>


** REFRIGERATOR
*<_refrigerator_>
	gen refrigerator= assets577
	label var refrigerator "Household has Refrigerator"
	la de lblrefrigerator 0 "No" 1 "Yes"
	label val refrigerator lblrefrigerator
*</_refrigerator>


** LAMP
*<_lamp_>
	gen lamp= assets585
	label var lamp "Household has Lamp"
	la de lbllamp 0 "No" 1 "Yes"
	label val lamp lbllamp
*</_lamp>


** BYCICLE
*<_bycicle_>
	gen bicycle= assets574
	label var bicycle "Household has Bicycle"
	la de lblbycicle 0 "No" 1 "Yes"
	label val bicycle lblbycicle
*</_bycicle>


** MOTORCYCLE
*<_motorcycle_>
	gen motorcycle= assets575
	label var motorcycle "Household has Motorcycle"
	la de lblmotorcycle 0 "No" 1 "Yes"
	label val motorcycle lblmotorcycle
*</_motorcycle>


** MOTOR CAR
*<_motorcar_>
	gen motorcar= assets576
	label var motorcar "Household has Motor car"
	la de lblmotorcar 0 "No" 1 "Yes"
	label val motorcar lblmotorcar
*</_motorcar>


** COW
*<_cow_>
	gen cow=s7c1q02a201
	label var cow "Household has Cow"
	la de lblcow 0 "No" 1 "Yes"
	label val cow lblcow
*</_cow>


** BUFFALO
*<_buffalo_>
	gen buffalo= s7c1q02a204
	label var buffalo "Household has Buffalo"
	la de lblbuffalo 0 "No" 1 "Yes"
	label val buffalo lblbuffalo
*</_buffalo>


** CHICKEN
*<_chicken_>
	gen chicken= s7c1q02a205
	label var chicken "Household has Chicken"
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
	gen spdef=spindex 
	la var spdef "Spatial deflator"
*</_spdef_>


** WELFARE
*<_welfare_>
	gen welfare=pcexp
	la var welfare "Welfare aggregate"
*</_welfare_>


** WELFARE IN NOMINAL TERMS
*<_welfarenom_>
	gen welfarenom=pcexp
	la var welfarenom "Welfare aggregate in nominal terms"
*</_welfarenom_>


** WELFARE SPATIALLY DEFLACTED
*<_welfaredef_>
	gen welfaredef=rpcexp
	la var welfaredef "Welfare aggregate spatially deflated"
*</_welfaredef_>


** WELFARE FOR SHARED PROSPERITY
*<_welfshprosperity_>
	gen welfshprosperity=pcexp
	la var welfshprosperity "Welfare aggregate for shared prosperity"
*</_welfshprosperity_>


** WELFARE MEASURE (TYPE)
*<_welfaretype_>
	gen welfaretype="EXP"
	la var welfaretype "Type of welfare measure (income, consumption or expenditure) for welfare, welfarenom, welfaredef"
*</_welfaretype_>


** WELFARE IF DIFFERENT WELFARE TYPE IS USED FROM WELFARE
*<_welfareother_>
	gen welfareother=.
	la var welfareother "Welfare Aggregate if different welfare type is used from welfare, welfarenom, welfaredef"
*</_welfareother_>


** WELFARE TYPOE FOR WELFAREOTHER
*<_welfareothertype_>
	gen welfareothertype=" "
	la var welfareothertype "Type of welfare measure (income, consumption or expenditure) for welfareother"
*</_welfareothertype_>


** WELFARE FOR NATIONAL POVERTY
*<_welfarenat_>
	gen welfarenat=welfare
	la var welfarenat "Welfare aggregate for national poverty"
*</_welfarenat_>	


*QUINTILE AND DECILE OF CONSUMPTION AGGREGATE

	levelsof year, loc(y)
	merge m:1 idh using "$shares\\BGD_fnf_`y'", keepusing (quintile_cons_aggregate decile_cons_aggregate) nogen
	note _dta: "BGD 2016" Food/non-food shares are not included because there is not enough information to replicate their composition. 


/*****************************************************************************************************
*                                                                                                    *
                                   NATIONAL POVERTY
*                                                                                                    *
*****************************************************************************************************/


** POVERTY LINE (NATIONAL)
*<_pline_nat_>
	drop pline_nat
	gen pline_nat=zu16
	label variable pline_nat "Poverty Line (National)"
*</_pline_nat_>


** HEADCOUNT RATIO (NATIONAL)
*<_poor_nat_>
	gen poor_nat=welfarenat<pline_nat if welfare!=.
	la var poor_nat "People below Poverty Line (National)"
	la define poor_nat 0 "Not-Poor" 1 "Poor"
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
	merge m:1 countrycode year urb using "$pricedata", nogen ///
	keepusing(countrycode year urb syear cpi`year'_w ppp`year') keep(3)
	drop urb
	
	
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
	gen poor_int=welfare<pline_int if welfare!=.
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

	keep countrycode year survey idh idp wgt pop_wgt strata psu vermast veralt urban int_month int_year  ///
		subnatid1 subnatid2 subnatid3 ownhouse landholding tenure water_orig piped_water water_jmp sar_improved_water  electricity toilet_orig sewage_toilet toilet_jmp sar_improved_toilet  landphone cellphone ///
	     computer internet hsize relationharm relationcs male age soc marital ed_mod_age everattend ///
	     atschool electricity literacy educy educat4 educat5 educat7 lb_mod_age lstatus /*lstatus_year*/ empstat /*empstat_year*/ njobs /*njobs_year*/ ///
	     ocusec nlfreason unempldur_l unempldur_u industry_orig industry occup_orig occup firmsize_l firmsize_u whours /*wage*/ ///
		  unitwage /*empstat_2 empstat_2_year industry_2 industry_orig_2 occup_2 wage_2 unitwage_2*/ contract healthins socialsec union rbirth_juris rbirth rprevious_juris rprevious yrmove ///
		 landphone cellphone computer radio television fan sewingmachine washingmachine refrigerator lamp bicycle motorcycle motorcar cow buffalo chicken  ///
		 pline_nat pline_int poor_nat poor_int spdef cpi ppp cpiperiod welfare welfshprosperity welfarenom welfaredef welfarenat /*quintile_cons_aggregate decile_cons_aggregate*/ welfareother welfaretype   welfareothertype  

** ORDER VARIABLES

	order countrycode year survey idh idp wgt pop_wgt strata psu vermast veralt urban int_month int_year  ///
		subnatid1 subnatid2 subnatid3 ownhouse landholding tenure water_orig piped_water water_jmp sar_improved_water  electricity toilet_orig sewage_toilet toilet_jmp sar_improved_toilet  landphone cellphone ///
	     computer internet hsize relationharm relationcs male age soc marital ed_mod_age everattend ///
	     atschool electricity literacy educy educat4 educat5 educat7 lb_mod_age lstatus /*lstatus_year*/ empstat /*empstat_year*/ njobs /*njobs_year*/ ///
	     ocusec nlfreason unempldur_l unempldur_u industry_orig industry occup_orig occup firmsize_l firmsize_u whours /*wage*/ ///
		  unitwage /*empstat_2 empstat_2_year industry_2 industry_orig_2 occup_2 wage_2 unitwage_2*/ contract healthins socialsec union rbirth_juris rbirth rprevious_juris rprevious yrmove ///
		 landphone cellphone computer radio television fan sewingmachine washingmachine refrigerator lamp bicycle motorcycle motorcar cow buffalo chicken  ///
		 pline_nat pline_int poor_nat poor_int spdef cpi ppp cpiperiod welfare welfshprosperity welfarenom welfaredef welfarenat /*quintile_cons_aggregate decile_cons_aggregate*/ welfareother welfaretype   welfareothertype  

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
	
	
	keep countrycode year survey idh idp wgt pop_wgt strata psu vermast veralt `keep' *type
	compress

	saveold "${output}\Data\Harmonized\BGD_2016_HIES_v01_M_v01_A_SARMD_IND.dta", replace version(12)
	saveold "D:\SOUTH ASIA MICRO DATABASE\SAR_DATABANK\__REGIONAL\Individual Files\BGD_2016_HIES_v01_M_v01_A_SARMD_IND.dta", replace version(12)

	*log close




******************************  END OF DO-FILE  *****************************************************/


