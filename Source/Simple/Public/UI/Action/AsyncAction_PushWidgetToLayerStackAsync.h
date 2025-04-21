// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameplayTagContainer.h"
#include "Engine/CancellableAsyncAction.h"
#include "AsyncAction_PushWidgetToLayerStackAsync.generated.h"

class APlayerController;
class UCommonActivatableWidget;

struct FStreamableHandle;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FPushWidgetToLayerStackAsyncDelegate, UCommonActivatableWidget*, UserWidget);

UCLASS()
class SIMPLE_API UAsyncAction_PushWidgetToLayerStackAsync : public UCancellableAsyncAction
{
	GENERATED_BODY()
public:
	UAsyncAction_PushWidgetToLayerStackAsync();

	virtual void Activate() override;
	virtual void Cancel() override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, meta=(WorldContext = "WorldContextObject", BlueprintInternalUseOnly="true"))
	static UAsyncAction_PushWidgetToLayerStackAsync* PushWidgetToLayerStackAsync(APlayerController* OwningPlayer, UPARAM(meta = (AllowAbstract=false)) TSoftClassPtr<UCommonActivatableWidget> InWidgetClass, UPARAM(meta = (Categories = "UI.Layer")) FGameplayTag LayerName);

public:

	UPROPERTY(BlueprintAssignable)
	FPushWidgetToLayerStackAsyncDelegate BeforePush;

	UPROPERTY(BlueprintAssignable)
	FPushWidgetToLayerStackAsyncDelegate AfterPush;

private:

	FGameplayTag LayerName;

	TWeakObjectPtr<APlayerController> OwningPlayerPtr;

	TSoftClassPtr<UCommonActivatableWidget> WidgetClass;

	TSharedPtr<FStreamableHandle> StreamingHandle;
};
