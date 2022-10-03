///////////////////////////////////////////////////////////////////////////////
// main.js
// =======
// main entry point of test_chart
//
//  AUTHOR: Song Ho Ahn(song.ahn@gmail.com)
// CREATED: 2021-11-03
// UPDATED: 2021-11-03
///////////////////////////////////////////////////////////////////////////////


// global vars
go = {};



///////////////////////////////////////////////////////////////////////////////
// main entry point
document.addEventListener("DOMContentLoaded", e =>
{
    log("page loaded");
    //Logger.hide();
    

    // generate data object for line graph
    let dataset = {
        xs: ["A", "B", "C", "D", "E"],  // x-values
        ys: [0, 10, 50, 20, 40]    // y-values
//    xs: ["2020-01-31", "2020-03-05", "2020-04-08", "2020-05-12", "2020-06-15", "2020-07-19", "2020-08-22", "2020-09-25", "2020-10-29", "2020-12-02", "2021-01-05", "2021-02-08", "2021-03-14", "2021-04-17", "2021-05-21", "2021-06-24", "2021-07-28", "2021-08-31", "2021-10-04"],  // x-values
//    ys: [0, 500, 1000, 1500,  2000, 2500, 3000, 3500, 4000, 4500, 5000]    // y-values
    };

    // draw line graph
    drawChart(dataset);
});




///////////////////////////////////////////////////////////////////////////////
function drawChart(dataset)
{
    // remove the previous chart if exists
    if(go.chart)
        go.chart.destroy();

    // get 2D rendering context from canvas
    let context = document.getElementById("chart").getContext("2d");

    // create new chart object
    go.chart = new Chart(context,
    {
        type: "line",                   // type of chart
        data:
        {
            labels: dataset.xs,         // data for x-axis
            datasets:
            [{
                data: dataset.ys,       // y-values to plot
                lineTension: 0,         // no Bezier curve
                borderColor: "d40000", // line color
                pointBackgroundColor: "d40000",
                borderWidth:1,
                backgroundColor: "f5aeae",
                fill: true,
                pointRadius:3

            }]
        },
        options:
        {
            maintainAspectRatio: false, // for responsive
            plugins:
            {
                title:
                {
                    display: true,
                    text: "Daily Confirmed Cases" // title for the chart
                },
                legend:
                {
                    display: false
                }
            }
        }
    });

    // debug
    log("X: " + dataset.xs);
    log("Y: " + dataset.ys);
    log(); // blank line
}
