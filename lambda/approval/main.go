package main

import (
	"context"
	"fmt"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sfn"
)

var sess = session.Must(session.NewSessionWithOptions(session.Options{
	SharedConfigState: session.SharedConfigEnable,
}))

var client = sfn.New(sess)

func main() {
	lambda.Start(HandleConnect)
}

func HandleConnect(ctx context.Context, request events.APIGatewayProxyRequest) (response events.APIGatewayProxyResponse, err error) {
	fmt.Printf("%+v\n", request)

	response = events.APIGatewayProxyResponse{
		StatusCode:        0,
		Headers:           map[string]string{},
		MultiValueHeaders: map[string][]string{},
		Body:              "",
		IsBase64Encoded:   false,
	}

	taskToken := request.QueryStringParameters["taskToken"]
	//statemachineName := request.QueryStringParameters["sm"]
	//executionName := request.QueryStringParameters["ex"]
	action := request.QueryStringParameters["action"]

	var message string

	if action == "approve" {
		message = `{ "Status": "Approved! Task approved" }`
		response.Body = message
	} else if action == "reject" {
		message = `{ "Status": "Rejected! Task rejected" }`
		response.Body = message

	} else {
		fmt.Println(fmt.Errorf("unrecognized action. expected: approve, reject"))
		response.Body = `{"Status": "Failed to process the request. Unrecognized Action."}`
		response.StatusCode = http.StatusNotFound
		return
	}

	input := sfn.SendTaskSuccessInput{
		Output:    aws.String(message),
		TaskToken: aws.String(taskToken),
	}

	out, err := client.SendTaskSuccess(&input)

	if err != nil {
		fmt.Println(err)
		response.StatusCode = http.StatusInternalServerError
		response.Body = "Failed"
		return
	}

	response.StatusCode = http.StatusOK

	fmt.Println(out)
	return
}
