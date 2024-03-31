package octo

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "libs:failz"
import "libs:http/client"

GIT_API_URL :: "https://api.github.com"

Repository :: struct {
	id:                int,
	name:              string,
	full_name:         string,
	owner:             struct {
		id:         int,
		avatar_url: string,
		url:        string,
	},
	private:           bool,
	html_url:          string,
	description:       string,
	fork:              bool,
	url:               string,
	stargazers_count:  int,
	watchers_count:    int,
	language:          string,
	forks_count:       int,
	open_issues_count: int,
	master_branch:     string,
	default_branch:    string,
	score:             int,
	license:           struct {
		name: string,
		url:  string,
	},
}

search_package :: proc() {
	using failz

	usage(len(os.args) < 3, SEARCH_USAGE)

	target := os.args[2]

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

	info("Status: %s", res.status)
	info("Headers: %v", res.headers)
	info("Cookies: %v", res.cookies)
	body_data, allocation, berr := client.response_body(&res)
	if berr != nil {
		fmt.printf("Error retrieving response body: %s", berr)
		return
	}
	defer client.body_destroy(body_data, allocation)

	repos: struct {
		total_count: int,
		items:       []Repository,
	}

	#partial switch body in body_data {
	case client.Body_Plain:
		catch(json.unmarshal(transmute([]byte)body, &repos))
		info("%#v", repos)
	}
}
