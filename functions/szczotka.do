program define szczotka

syntax varlist [if] [in] [, measure(string) label(string) zgr(string) g det]

tempname A A1 A2 a b c d e var var2 obs obs2 obs3 kryt iter Kryt krok  list licz list2 spec
local `spec' = "`if'" + "`in'"
tempvar lab gr
mat dis `A'=`varlist' ``spec'', `measure'

local `licz'=_N
local `obs'=colsof(`A')
local `Kryt'=0
local `obs2'=``obs''-1
forvalues i=1/``obs''	{
	local `list'="``list''"+" o`i'"
}

if "`label'"!=""	{
	qui gen `lab'=`label'
			}
else	{
	qui gen `lab'=_n
	}

di "Porządkowanie początkowe:"
di "``list''"
di "Porządkowanie w kolejnych iteracjach:"
local `krok'=1
local `iter'=0

forvalues l=1/``obs''	{
forvalues i=1/``obs''	{
	forvalues j=1/``obs''	{
			local ++`iter'
			if `i'!=`j'	{
					mat `A1'=`A'
					mat `A2'=`A'
					forvalues k=1/``obs''	{
				
						mat `A1'[`j',`k']=`A'[`i',`k']
						mat `A1'[`i',`k']=`A'[`j',`k']	
						mat `A2'[`j',`k']=`A'[`i',`k']
						mat `A2'[`i',`k']=`A'[`j',`k']	
								}
					forvalues k=1/``obs''	{
						mat `A1'[`k',`i']=`A2'[`k',`j']
						mat `A1'[`k',`j']=`A2'[`k',`i']
								}
			
					//Obliczanie kryterium
					local `kryt'=0
					forvalues x=1/``obs2''	{
						local `obs3'=``obs''-`x'
	
						local `d'=0
						forvalues y=1/``obs3''	{
							local `d'=``d''+`A1'[`x',`y']
									}
						local `kryt'=``kryt''+`x'*``d''
	
								}


					if ``kryt''>``Kryt''	{
						local ++`krok'
						local `Kryt'=``kryt''
						mat `A'=`A1'
						tokenize ``list''
						local `list2'=""
						forvalues k=1/``obs''	{
							if `k'!=`i' & `k'!=`j'	{
								local `list2'="``list2''" + " ``k''"
										}
							if `k'==`i'		{	
								local `list2'="``list2''" + " ``j''"
										}
							if `k'==`j'		{	
								local `list2'="``list2''" + " ``i''"
										}
									}
						local `list'="``list2''"
						di  "W kroku:" ``krok'' " po " ``iter'' " iteracjach " "przy funkcji kryterium= " ``kryt'' " Otrzymano uporządkowanie:" 								
		
						di "``list''"
								}
					}
				}
			}
			}
di ``iter''
//Porządkowanie i nadawanie etykiet obiektom



if "`label'"!="" | "`g'"!=""	{

local `obs2'=c(N)
tempvar v1 v2 v3
qui gen `v3'=_n
qui gen `v1'=0
qui gen `v2'=0
qui replace `v1'=1 ``spec''
local `a'=1
	forvalues i=1/``obs2''	{
		if `v1'==1 in `i'	{
		qui replace `v1'=``a'' in `i'
		local ++`a'
					}
				}
tokenize ``list''
forvalues i=1/``obs''	{
local `a'=substr("``i''",2,length("``i''")-1)
local `b'=0
	forvalues j=1/``obs2''	{
		qui sum `v1' in `j'
		if r(mean)>=1	{
			local ++`b'
			if ``b''==``a''	{
				qui replace `v2'=`i' in `j'
					}
				}
				
		}
		}
	sort `v2'

//Wynik z etykietami
if  "`label'"!=""	{
di "Ostateczne uporządkowanie obiektów metodą Szczotki"


tempname up
qui gen `up'=_n
char `up' [varname] "Uporządkowanie"
char `lab' [varname] "Obiekt"

list `up'  `lab' if `v1'>0,  noobs subvarname abb(20) sep(``licz'')
sort `v3'
			}

//Grupowanie
if "`g'"!=""	{
	tempname B C D E W a1 a2 a3 s t kryt s1 s2 s3
	tempvar gr wer tgr fdgr ifdgr
	qui gen `tgr'="null"
	qui gen `fdgr'=.
	qui gen `ifdgr'=.
	mat dis `A'=`varlist' ``spec''
	mat def `B'=J(1,``obs2'',.)
	mat def `C'=J(1,``obs2'',.)
	
	qui gen `gr'=0
	qui gen `wer'=0
	qui replace `wer'=1 ``spec''
	local `obs'=c(N)
	local `a'=1
	forvalues i=1/``obs''	{
		qui replace `gr'=``a'' in `i' if `wer'==1
		qui sum `wer' in `i'
			if r(mean)==1		{
				local ++`a'
						}
				}
	
	forvalues i=1/``obs2''	{
		mat `B'[1,`i']=`A'[`i',`i'+1]
				}



	local `a'=0
	forvalues i=1/``obs2''	{	
		if `B'[1,`i']>``a''	{
			local `a'=`B'[1,`i']
			local `e'=`i'
					}
				}
	mat `B'[1,``e'']=`B'[1,``e'']-0.000001
	local `obs2'=colsof(`A')-1
	forvalues j=1/``obs2''	{

		local `kryt'=0
		tempvar gr`j'
		local `b'=``a''
		forvalues i=1/``obs2''	{	
			if `B'[1,`i']<``b''	{
				local `b'=`B'[1,`i']
				local `c'=`i'
			
				
						}
					}
	
		mat `B'[1,``c'']=``a''
	
		local `d'=``c''+1
		
	

		forvalues i=``d''/``obs''	{
			qui sum `gr' in `i'
			qui replace `gr'=r(mean)-1 in `i'
						}
		qui sum `gr' in ``c''
		local `s'=r(mean)
		local `t'=""
		forvalues i=1/``obs''		{
			qui sum `gr' in `i'
			if r(mean)==``s''		{
				local `t'="``t''"+" o`i'"
							}
						}
		qui replace `tgr'="``t''" in `j'
		
		mkmat `gr', matrix(`D')
				
		local `e'=rowsof(`D')-1
	
		forvalues i=1/``e''	{
			if `D'[`i',1]==`D'[`i'+1,1]	{
				local `kryt'=``kryt''+`A'[`i',`i'+1]
			
							}
					}
	
		mat `C'[1,`j']=``kryt''
		qui replace `fdgr'=``kryt'' in `j'

		qui gen `gr`j''=`gr'
		if "`det'"!=""		{
	
			di "Grupowanie obiektów w kroku `j'"
			di _newline(1)
			di "     Obiekt      Grupa"
			list `lab' `gr`j'' ``spec'', noobs noheader
			di "Wartość funkcji kryterium: ``kryt''"
					}
	
	


				}

	forvalues i=1/``e''	{
		qui sum `fdgr' in `i'
		local `s1'=r(mean)
		local `s3'=`i'+1
		qui sum `fdgr' in ``s3''
		local `s2'=r(mean)
		qui replace `ifdgr'=``s2''/``s1'' in ``s3''
				}
	di _newline(2)
	di "######      Podsumowanie grupowania      ######"
	tempvar krok
	qui gen `krok'=_n
	format `fdgr' `ifdgr' %9.3f
	char `krok' [varname] "Krok"
	char `fdgr' [varname] "F. kryterium"
	char `ifdgr' [varname] "Iloraz f. kryt."
	char `tgr' [varname] "Obiekty łączone w danym kroku"
	list  `krok' `fdgr' `ifdgr' `tgr' in 1/``e'', subvarname noobs abb(20)
	
	local `e'=``e''-1
	mat def `E'=J(1,``e'',.)
	forvalues i=1/``e''	{
		mat `E'[1,`i']=`C'[1,`i'+1]/`C'[1,`i']
				}

	local `a'=0
	local `b'=0
	while ``b''==0	{
		local ++`a'
		if `E'[1,``a'']<`E'[1,``a''+1]		{
			local `b'=1
							}
			}
	local `a'=``a''+2
	
	char `gr``a''' [varname] "Nr grupy"
	char `lab' [varname] "Obiekt"
	di "Iloraz funkcji dobroci dopasowania wzrasta po raz pierwszy w kroku ``a''"
	di _newline(1)
	di "Grupowanie obiektów metodą Spatha-Szczotki (rozwiązanie quasi-optymalne):"
	list `lab' `gr``a''' ``spec'', noobs subvarname abb(33) sepby(`gr``a''')

	if "`zgr'"!=""	{
		qui gen `zgr'=`gr``a''' ``spec''
			}
	
	}

sort `v3'
}
end
//end
