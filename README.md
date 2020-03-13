```@meta
EditURL = "<unknown>/covid-19.jl"
```

# COVID-19 Analysis
*This is a very simple estimate of COVID-19 impacts, and I don't claim to know anything other than how to produce a nice figure and do simple math*

```@example covid-19
using Dates
using PlotlyJS
using DataFrames
using CSV
```

```@example covid-19
function cases(days::Day, current_cases, doubling_time)
    dbl_period = days/doubling_time
    return current_cases * (2 ^ dbl_period)
end
```

```@example covid-19
function plot_covid(days, current_cases, doubling_time = Day(7), hosp_rate = 0.1, death_rate = 0.03)
    td = today()
    dates = td:doubling_time:(td+days)
    case_count = [cases(d-td, current_cases, doubling_time) for d in dates]
    total_cases = scatter(x = dates, y = case_count, name = "Infections")
    hosp = scatter(x = dates, y = case_count.*hosp_rate, name = "Hospitalizations")
    deaths = scatter(x = dates, y = case_count.*death_rate, name = "Deaths")
    plot([total_cases, hosp, deaths])
end
```

## COVID-19 parameters
- According to [this article](https://www.jhsph.edu/news/news-releases/2020/new-study-on-COVID-19-estimates-5-days-for-incubation-period.html), the estimated doubling time of COVID-19 is ~5 days.
- According to [the WHO](https://www.who.int/docs/default-source/coronaviruse/situation-reports/20200306-sitrep-46-covid-19.pdf?sfvrsn=96b04adf_2), the mortality rate of COVID-19 is ~3%.
- I don't know where the 10% hospitalization rate comes from.

Let's use data from the [WHO]("http://cowid.netlify.com/data/full_data.csv") to get data for the whole world (including the U.S.).

```@example covid-19
who_data_url = "http://cowid.netlify.com/data/full_data.csv"
who_data_file = download(who_data_url)
who_data = DataFrame(CSV.read(who_data_file))
```

Also, JHU has put together some more detailed data

```@example covid-19
jh_data_url = "https://data.humdata.org/hxlproxy/api/data-preview.csv?url=https%3A%2F%2Fraw.githubusercontent.com%2FCSSEGISandData%2FCOVID-19%2Fmaster%2Fcsse_covid_19_data%2Fcsse_covid_19_time_series%2Ftime_series_19-covid-Confirmed.csv"
jh_data_file = download(jh_data_url)
jh_data = DataFrame(CSV.read(jh_data_file))
```

## Colorado
data processing

```@example covid-19
co_data = jh_data[.!ismissing.(jh_data[!,Symbol("Province/State")]) .& (jh_data[!,Symbol("Province/State")].=="Colorado"),:]
co_data = melt(co_data,names(co_data)[1:4],variable_name = :Date, value_name =:cases)
co_data.Date = Date.(String.(co_data.Date),"m/d/y") + Year(2000)
recent_cases = co_data[co_data.Date .== maximum(co_data.Date),:cases][1]
```

Plot the colorado projection using the most recent case count
<iframe id="igraph" scrolling="no" style="border:none;" seamless="seamless" src="./CO.html" height="525" width="100%"></iframe>

## US
data processing

```@example covid-19
us_data = jh_data[.!ismissing.(jh_data[!,Symbol("Country/Region")]) .& (jh_data[!,Symbol("Country/Region")].=="US"),:]
us_data = us_data[.!occursin.(",", us_data[!,Symbol("Province/State")]), :]
us_data = melt(us_data,names(us_data)[1:4],variable_name = :Date, value_name =:cases)
us_data.Date = Date.(String.(us_data.Date),"m/d/y") + Year(2000)
us_data = aggregate(us_data[!,[:Date,:cases]], :Date, sum)
recent_us_cases = us_data[us_data.Date .== maximum(us_data.Date),:cases_sum][1]
```

Plot the US projection based on the most recent case  count
<iframe id="igraph" scrolling="no" style="border:none;" seamless="seamless" src="./US.html" height="525" width="100%"></iframe>

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

