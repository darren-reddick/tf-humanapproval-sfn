package main

import (
	"context"
	"fmt"
	"net/url"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	sns "github.com/aws/aws-sdk-go/service/sns"
)

type ApprovalSendEmailEvent struct {
	APIGatewayEndpoint string `json:"APIGatewayEndpoint,omitempty"`
	SNSTopicArn        string `json:"SNSTopicArn,omitempty"`
	ExecutionContext   struct {
		Execution struct {
			Id    string `json:"Id,omitempty"`
			Input struct {
				Comment string `json:"Comment,omitempty"`
			} `json:"Input,omitempty"`
			Name      string `json:"Name,omitempty"`
			RoleArn   string `json:"RoleArn,omitempty"`
			StartTime string `json:"StartTime,omitempty"`
		} `json:"Execution,omitempty"`
		StateMachine struct {
			Id   string `json:"Id,omitempty"`
			Name string `json:"Name,omitempty"`
		} `json:"StateMachine,omitempty"`
		State struct {
			Name        string `json:"name,omitempty"`
			EnteredTime string `json:"EnteredTime,omitempty"`
			RetryCount  int    `json:"RetryCount,omitempty"`
		} `json:"State,omitempty"`
		Task struct {
			Token string `json:"Token,omitempty"`
		} `json:"Task,omitempty"`
	} `json:"ExecutionContext,omitempty"`
}

var sess = session.Must(session.NewSessionWithOptions(session.Options{
	SharedConfigState: session.SharedConfigEnable,
}))

var client = sns.New(sess)

func main() {
	lambda.Start(HandleConnect)
}

func HandleConnect(ctx context.Context, request ApprovalSendEmailEvent) (err error) {
	approveUrl := request.APIGatewayEndpoint +
		"/execution?action=approve&ex=" + request.ExecutionContext.Execution.Name + "&sm=" + request.ExecutionContext.StateMachine.Name +
		"&taskToken=" + url.QueryEscape(request.ExecutionContext.Task.Token)

	rejectUrl := request.APIGatewayEndpoint +
		"/execution?action=reject&ex=" + request.ExecutionContext.Execution.Name + "&sm=" + request.ExecutionContext.StateMachine.Name +
		"&taskToken=" + url.QueryEscape(request.ExecutionContext.Task.Token)

	snsTopic := request.SNSTopicArn

	emailMessage := "Welcome! \n\n"
	emailMessage += "This is an email requiring an approval for a step functions execution. \n\n"
	emailMessage += "Please check the following information and click \"Approve\" link if you want to approve. \n\n"
	emailMessage += "Execution Name -> " + request.ExecutionContext.Execution.Name + "\n\n"
	emailMessage += "Approve " + approveUrl + "\n\n"
	emailMessage += "Reject " + rejectUrl + "\n\n"
	emailMessage += "Thanks for using Step functions!"

	input := sns.PublishInput{
		Message:  aws.String(emailMessage),
		Subject:  aws.String("Required approval from AWS Step Functions"),
		TopicArn: &snsTopic,
	}

	out, err := client.Publish(&input)

	if err != nil {
		fmt.Println(err)
		return err
	}

	fmt.Println(out)
	return
}
