program define helw
syntax varlist [if] [in] [fweight iweight pweight] [, r(real 0.5) mm t t_level(real 0.05) med]

if ("`mm'"!="" & "`t'"!="") |  ("`mm'"!="" & `r'!=0.5) | ("`t'"!="" & `r'!=0.5) {
	di as error "Opcje mm, t i r() nie moga wystepowac lacznie. Zdecyduj sie na jeden sposob ustalenia krytycznej wartosci wsp. korelacji"
	error
}

if (`r'==0.5 & "`mm'"=="" & "`t'"=="")	{
di 	"Przyjeto domyslny poziom wartosci krytycznej wsp. korelacji"
}

if (`t_level'==0.05 &  "`t'"!="")	{
di 	"Przyjeto domyslny poziom wartosci krytycznej testu t-studenta rowny 0.05 przy okreslaniu krytycznego poziomu wsp. korelacji. Chcac go zmienic uzyj opcji t_level()"
}

if ("`mm'"!="" )	{
di 	"Wartosc krytyczna wspolczynnika korelacji obliczona metoda minmax"
}

tempname zmienne i a aa b A B m m1 m2 m3 m4 m5 ts rr sat centr max maxi min suma krok spec
tempvar zmc zms ci
local `i'=1
local `a'=0
local `spec' = "`if'" + "`in'" + "`weight'"


qui gen `ci'=""
local `zmienne'="`varlist'" 
foreach j of varlist ``zmienne''	{
local `a'=``a''+1
}

//Ustalanie krytycznej warto ci wsp. korelacji
if "`mm'"==""	& "`t'"==""	{
local `rr'=`r'
}
else	{
	if "`mm'"!=""	{
				qui corr ``zmienne'' ``spec''
				mat def `A'=r(C)
				forvalues i=1/``a''	{
					forvalues j=1/``a''	{
					mat `A'[`i',`j']=(`A'[`i',`j']^2)^0.5
								}
							}
				mat def `B'=J(``a'',1,.)
				
				forvalues j=1/``a''	{
					local `max'=0
					forvalues i=1/``a''	{
						if `A'[`i',`j']>=``max'' & `A'[`i',`j']!=1	{
							local `max'=`A'[`i',`j']
										}
								}
					mat `B'[`j',1]=``max''
							}
				local `min'=1
				forvalues i=1/``a''	{
					if `B'[`i',1]<=``min''	{
					local `min'=`B'[`i',1]
									}
							}
					local `rr'=``min''
			}
	
		else	{
			if "`t'"!=""		{
					tokenize "``zmienne''"
					qui sum `1'
					local `b'=r(N)-2
					local `ts'=invttail(``b'',`t_level')^2
					local `rr'=(``ts''/(``ts''+``b''))^0.5
						}
	
			}
	}

di "r krytyczne= "  %-9.3f ``rr''

local `krok'=0
qui gen `zmc'=""
qui gen `zms'=""

while ``a''>0	{
tokenize "``zmienne''"
local `sat'=""


qui corr ``zmienne'' ``spec''
local `krok'=``krok''+1

di _newline(2)
di "*************KROK ``krok''**********"
di _newline(1)
mat def `A'=r(C)

forvalues i=1/``a''	{
	forvalues j=1/``a''	{
	mat `A'[`i',`j']=(`A'[`i',`j']^2)^0.5
	}
}
mat def `B'=J(``a'',1,.)
if "`med'"==""	{

forvalues i=1/``a''	{
	local	`suma'=-1
	forvalues j=1/``a''	{
		local	`suma'=``suma''	+(`A'[`i',`j'])
		}
		mat `B'[`i',1]=``suma''
}
}
else	{
if ``a''>1	{
local `aa'=``a''-1
forvalues i=1/``a''	{
	local `m'=""
	forvalues j=1/``a''	{
			if `i'!=`j'	{
			local `m1'= `A'[`i',`j']
			local `m'="``m''"+" ``m1''"	
					}				
				}
			local `m' : list sort `m'
			if mod(``aa'',2)==0	{
				
				local `m1'=(``aa'')/2
				
				
				local `m2'=``m1''+1
				
			
				local `m5'= word("``m''",``m1'')
				local `m4'= word("``m''",``m2'')
				local `m3'=(``m4''+``m5'')/2
								}
			else			{
				
				local `m1'=(``aa''+1)/2
				
				local `m3'= word("``m''",``m1'')
				
								
							}
				mat `B'[`i',1]=``m3''
				
			}
}
else	{
mat `B'[1,1]=1
}
}
local `max'=0
local `maxi'=0
local `centr'=""


forvalues i=1/``a''	{
	if `B'[`i',1]>=``max''	{
		local `max'=`B'[`i',1]
		local `maxi'=`i'
		local `centr'="``i''"
		
	}
	
}
forvalues i=1/``a''	{
	if `A'[`i',``maxi'']>``rr'' &``maxi''!=`i'	{
		local `sat'="``sat''"+" ``i''"
							}
			}
if "``sat''"!=""	{
	di "Zmienna centralna wyr niona w kroku ``krok'':"
	di "``centr''"

	qui replace `ci'="zmienna centralna" in ``krok''
			
	di "Zmienne satelitarne odpowiadajace zmiennej ``centr'':"

	di "``sat''"
	di "Wsp czynniki korelacje zmiennej centralnej i zmiennych satelitarnych:"
	corr ``centr'' ``sat''
	}
else	{
	di "Zmienna izolowana wyr niona w kroku ``krok'':"
	qui replace `ci'="zmienna izolowana" in ``krok''
	di "``centr''"

}


qui replace `zmc'="``centr''" in ``krok''
qui replace `zms'="``sat''" in ``krok''
local `zmienne' : list `zmienne' - `centr'
local `zmienne' : list `zmienne' - `sat'
local `b' = wordcount("``sat''")
local `a'=``a''-1 -``b''

}

//Podsumowanie

di _newline(3)
di "*************Podsumowanie ***********"
di _newline(1)
if ``krok''==1	{
di "Metoda Hellwiga wyr ni a jedn  zmienn  reprezentanta"
}
else	{
	if ``krok''<5	{
	di "Metoda Hellwiga wyr ni a ``krok'' zmienne reprezentanty"
	}
	else	{
	di "Metoda Hellwiga wyr ni a ``krok'' zmiennych reprezentant w"
	}
}

char `ci' [varname] "Typ zmiennej reprezentanta"
char `zmc' [varname] "Zmienne reprezentanty"
char `zms' [varname] "Zmienne sat. dla zm.centralnych"

list `zmc' `ci' `zms' in 1/``krok'', t notr separator(1) abbreviate(33) subvarname noobs
qui drop `zmc' `zms'

end
//end
