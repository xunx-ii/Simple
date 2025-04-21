// Fill out your copyright notice in the Description page of Project Settings.


#include "UI/Action/AsyncAction_PushWidgetToLayerStackAsync.h"
#include "UObject/Stack.h"
#include "SimpleGameInstance.h"
#include "Engine/Engine.h"
#include "Player/SimpleLocalPlayer.h"
#include "GameFramework/PlayerController.h"
#include "UI/SimplePrimaryLayout.h"
#include "Widgets/CommonActivatableWidgetContainer.h"
#include "CommonActivatableWidget.h"

UAsyncAction_PushWidgetToLayerStackAsync::UAsyncAction_PushWidgetToLayerStackAsync()
{
	
}

void UAsyncAction_PushWidgetToLayerStackAsync::Activate()
{
	APlayerController* PlayerController = OwningPlayerPtr.Get();

	if (!PlayerController)
	{
		SetReadyToDestroy();
	}

	USimpleGameInstance* SimpleGameInstance = Cast<USimpleGameInstance>(PlayerController->GetGameInstance());

	if (!SimpleGameInstance)
	{
		SetReadyToDestroy();
	}

	USimplePrimaryLayout* SimplePrimaryLayout = SimpleGameInstance->GetPrimaryLayout(Cast<USimpleLocalPlayer>(PlayerController->Player));

	if (!SimplePrimaryLayout)
	{
		SetReadyToDestroy();
	}

	TWeakObjectPtr<UAsyncAction_PushWidgetToLayerStackAsync> WeakThis = this;

	StreamingHandle = SimplePrimaryLayout->PushWidgetToLayerStackAsync<UCommonActivatableWidget>(LayerName, WidgetClass, [this, WeakThis](EAsyncWidgetLayerState State, UCommonActivatableWidget* Widget) {
		if (WeakThis.IsValid())
		{
			switch (State)
			{
			case EAsyncWidgetLayerState::Initialize:
				BeforePush.Broadcast(Widget);
				break;
			case EAsyncWidgetLayerState::AfterPush:
				AfterPush.Broadcast(Widget);
				SetReadyToDestroy();
				break;
			case EAsyncWidgetLayerState::Canceled:
				SetReadyToDestroy();
				break;
			}
		}
		SetReadyToDestroy();
		});
}

void UAsyncAction_PushWidgetToLayerStackAsync::Cancel()
{
	Super::Cancel();

	if (StreamingHandle.IsValid())
	{
		StreamingHandle->CancelHandle();
		StreamingHandle.Reset();
	}
}

UAsyncAction_PushWidgetToLayerStackAsync* UAsyncAction_PushWidgetToLayerStackAsync::PushWidgetToLayerStackAsync(APlayerController* InOwningPlayer, TSoftClassPtr<UCommonActivatableWidget> InWidgetClass, FGameplayTag InLayerName)
{
	if (InWidgetClass.IsNull())
	{
		FFrame::KismetExecutionMessage(TEXT("PushContentToLayerForPlayer was passed a null WidgetClass"), ELogVerbosity::Error);
		return nullptr;
	}

	if (UWorld* World = GEngine->GetWorldFromContextObject(InOwningPlayer, EGetWorldErrorMode::LogAndReturnNull))
	{
		UAsyncAction_PushWidgetToLayerStackAsync* Action = NewObject<UAsyncAction_PushWidgetToLayerStackAsync>();
		Action->WidgetClass = InWidgetClass;
		Action->OwningPlayerPtr = InOwningPlayer;
		Action->LayerName = InLayerName;
		Action->RegisterWithGameInstance(World);

		return Action;
	}

	return nullptr;
}
