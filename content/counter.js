async function fetchCount() {
    let response = await fetch('https://05li2opwre.execute-api.us-east-1.amazonaws.com/prod/getcount');
    let data = await response.text();
    console.log(data);
    document.getElementById("hits").innerHTML = data
}
fetchCount();