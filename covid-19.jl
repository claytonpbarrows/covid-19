# # COVID-19 Analysis
# Checkout the [webpage with live plots](https://claytonpbarrows.github.io/covid-19/).
# And if you're intereested:
# - [the github repository](https://github.com/claytonpbarrows/covid-19/).
# - [the notebook](https://nbviewer.jupyter.org/github/claytonpbarrows/covid-19/blob/master/covid-19.ipynb).
# - And if you want to run the notebook interactively through binder (slow), you can do so [here](https://mybinder.org/v2/gh/claytonpbarrows/covid-19/master/).
#
# *This is a very simple estimate of COVID-19 impacts, and I don't claim to know anything other than how to produce a nice figure and do simple math. __So please don't misinterpret anything here__.*
#
# ### Dependencies
using Dates
using PlotlyJS
using DataFrames
using CSV

# A simple model for calculating cases based on a constatnt doubling time:
function cases(days::Day, current_cases, doubling_time::Day)
    dbl_period = days/doubling_time
    return current_cases * (2 ^ dbl_period)
end

# A simple model for calculating instantanious case load given a recovery time:
# *note that the instantaneous case calculation assumes that the death time is the same as the recovry time*
function instantanious_cases(dates, cumulative_cases, hosp_rate, death_rate, recovery_time)
    recovery_dates = dates .+ recovery_time
    recovery_lag = length(dates[dates .< recovery_dates[1]])
    recovered_cases = vcat(zeros(recovery_lag), cumulative_cases[1:end-recovery_lag])
    instant_cases = cumulative_cases - recovered_cases - recovered_cases .* death_rate
    instant_hosp = instant_cases .* hosp_rate
    return instant_cases, instant_hosp
end

# Here is a function to generate plotly figures based on the simple virus model parameters.

function plot_covid(days, current_cases, doubling_time = Day(7), hosp_rate = 0.1, death_rate = 0.03)
    td = today()
    dates = td:doubling_time:(td+days)
    cumulative_cases = [cases(d-td, current_cases, doubling_time) for d in dates]
    instant_cases, instant_hosp = instantanious_cases(dates, cumulative_cases, hosp_rate, death_rate, Day(10))
    total_cases = scatter(x = dates, y = cumulative_cases, name = "Cumulative Infections")
    #total_hosp = scatter(x = dates, y = cumulative_cases.*hosp_rate, name = "Cumulative Hospitalizations")
    total_deaths = scatter(x = dates, y = cumulative_cases.*death_rate, name = "Cumulative Deaths")
    inst_cases = scatter(x = dates, y = instant_cases, name = "Instantanious Infections")
    inst_hosp = scatter(x = dates, y= instant_hosp, name = "Instantanious Hospitalizations")
    plot([total_cases, total_deaths, inst_cases, inst_hosp])
end

# ## COVID-19 parameters
# - According to [this article](https://www.jhsph.edu/news/news-releases/2020/new-study-on-COVID-19-estimates-5-days-for-incubation-period.html), the estimated doubling time of COVID-19 is ~5 days.
# - According to [the WHO](https://www.who.int/docs/default-source/coronaviruse/situation-reports/20200306-sitrep-46-covid-19.pdf?sfvrsn=96b04adf_2), the mortality rate of COVID-19 is ~3%.
# - The 10% hospitalization rate comes from [this article](https://www.statnews.com/2020/03/10/simple-math-alarming-answers-covid-19/), but the sources for that figure in the article are dubious at best.
#

# JHU has put together some more detailed data, and [HDX has put it in a useful format](https://data.humdata.org/dataset/novel-coronavirus-2019-ncov-cases).
jh_data = DataFrame(CSV.read(download("https://data.humdata.org/hxlproxy/api/data-preview.csv?url=https%3A%2F%2Fraw.githubusercontent.com%2FCSSEGISandData%2FCOVID-19%2Fmaster%2Fcsse_covid_19_data%2Fcsse_covid_19_time_series%2Ftime_series_19-covid-Confirmed.csv")))

# ## Colorado
# data processing
co_data = jh_data[.!ismissing.(jh_data[!,Symbol("Province/State")]) .& (jh_data[!,Symbol("Province/State")].=="Colorado"),:]
co_data = melt(co_data,names(co_data)[1:4],variable_name = :Date, value_name =:cases)
co_data.Date = Date.(String.(co_data.Date),"m/d/y") + Year(2000)
recent_cases = co_data[co_data.Date .== maximum(co_data.Date),:cases][1]

# Plot the colorado projection using the most recent case count:
#nb plot_covid(Day(60), recent_cases, Day(5))
co = plot_covid(Day(60), recent_cases, Day(5)) #src
savefig(co, "CO.html",  :embed) #src
#md plot_covid(Day(60), recent_cases, Day(5))
#md # <iframe id="igraph" scrolling="no" style="border:none;" seamless="seamless" src="./CO.html" height="525" width="100%"></iframe>

# ## US
# data processing
us_data = jh_data[.!ismissing.(jh_data[!,Symbol("Country/Region")]) .& (jh_data[!,Symbol("Country/Region")].=="US"),:]
us_data = us_data[.!occursin.(",", us_data[!,Symbol("Province/State")]), :]
us_data = melt(us_data,names(us_data)[1:4],variable_name = :Date, value_name =:cases)
us_data.Date = Date.(String.(us_data.Date),"m/d/y") + Year(2000)
us_data = aggregate(us_data[!,[:Date,:cases]], :Date, sum)
recent_us_cases = us_data[us_data.Date .== maximum(us_data.Date),:cases_sum][1]

# Plot the US projection based on the most recent case  count:
#nb plot_covid(Day(100), recent_us_cases, Day(5))
us = plot_covid(Day(60), recent_us_cases, Day(5)) #src
savefig(us, "US.html", :embed) #src

#md plot_covid(Day(60), recent_us_cases, Day(5))
#md # <iframe id="igraph" scrolling="no" style="border:none;" seamless="seamless" src="./US.html" height="525" width="100%"></iframe>

using Literate #src
Literate.notebook("covid-19.jl", ".") #src
Literate.markdown("covid-19.jl", ".", documenter = false) #src
mv("covid-19.md", "README.md", force=true) #src