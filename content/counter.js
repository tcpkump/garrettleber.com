async function fetchCount() {
    let response = await fetch('https://y3lwtge382.execute-api.us-east-1.amazonaws.com/prod/getcount');
    let data = await response.text();
    console.log(data);
    document.getElementById("hits").innerHTML = data
}
fetchCount();