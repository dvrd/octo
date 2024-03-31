package octo

import "core:fmt"
import "core:os"
import "core:strings"
import "libs:http/client"

GIT_API_URL :: "https://api.github.com"

get :: proc() {
}

search_package :: proc() {
	usage(len(os.args) < 3, SEARCH_USAGE)

	target := os.args[2]

	headers: []string =  {
		"Accept: application/json",
		"X-GitHub-Api-Version: 2022-11-28",
		fmt.tprintf("Authorization: Bearer %s", os.get_env("GITHUB_PERSONAL_TOKEN")),
	}
	q := fmt.tprintf("q=%s", strings.join({target, "lang:odin"}, "+"))
	query := strings.join({q, "sort=start", "order=desc"}, "&")
	uri := strings.join({GIT_API_URL, "/search/repositories?", query}, "")

	info("Fetching: %s", uri)
	res, err := client.get(uri)
	if err != nil {
		fmt.printf("Request failed: %s", err)
		return
	}
	defer client.response_destroy(&res)

	info("Status: %s\n", res.status)
	info("Headers: %v\n", res.headers)
	info("Cookies: %v\n", res.cookies)
	body, allocation, berr := client.response_body(&res)
	if berr != nil {
		fmt.printf("Error retrieving response body: %s", berr)
		return
	}
	defer client.body_destroy(body, allocation)

	info("%v", body)
}
