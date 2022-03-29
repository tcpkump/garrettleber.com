async function fetchCount() {
    let response = await fetch('https://us-central1-lebergarrett-com.cloudfunctions.net/lebergarrett-cloudfunction-ec9354a');
    let data = await response.text();
    console.log(data);
    document.getElementById("hits").innerHTML = data
}
fetchCount();