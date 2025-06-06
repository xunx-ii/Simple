// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"
#include "GameplayTagContainer.h"
#include "SimpleGameInstance.generated.h"

class AHUD;
class ULocalPlayer;
class USimpleGameWidget;
class USimpleLocalPlayer;
class USimplePrimaryLayout;
class UCommonActivatableWidget;

USTRUCT()
struct FRootViewportLayoutInfo
{
	GENERATED_BODY()
public:
	UPROPERTY(Transient)
	TObjectPtr<ULocalPlayer> LocalPlayer = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<USimplePrimaryLayout> RootLayout = nullptr;

	UPROPERTY(Transient)
	bool bAddedToViewport = false;

	FRootViewportLayoutInfo() {}
	FRootViewportLayoutInfo(ULocalPlayer* InLocalPlayer, USimplePrimaryLayout* InRootLayout, bool bIsInViewport)
		: LocalPlayer(InLocalPlayer)
		, RootLayout(InRootLayout)
		, bAddedToViewport(bIsInViewport)
	{}

	bool operator==(const ULocalPlayer* OtherLocalPlayer) const { return LocalPlayer == OtherLocalPlayer; }
};

UCLASS()
class SIMPLE_API USimpleGameInstance : public UGameInstance
{
	GENERATED_BODY()
	
public:
	USimpleGameInstance(const FObjectInitializer& ObjectInitializer);

	void NotifyPlayerAdded(USimpleLocalPlayer* LocalPlayer);
	void NotifyPlayerDestroyed(USimpleLocalPlayer* LocalPlayer);
	
	virtual int32 AddLocalPlayer(ULocalPlayer* NewPlayer, FPlatformUserId UserId) override;
	virtual bool RemoveLocalPlayer(ULocalPlayer* ExistingPlayer) override;

	USimplePrimaryLayout* GetPrimaryLayout(USimpleLocalPlayer* LocalPlayer);

	UFUNCTION(BlueprintCallable, Category = "Simple | UI")
	bool PushWidgetToLayerStackOfGamePlayTag(UPARAM(meta = (AllowAbstract = false)) TSoftClassPtr<UCommonActivatableWidget> WidgetClass, UPARAM(meta = (Categories = "UI.Layer")) FGameplayTag LayerName);
protected:
	void CreateLayoutWidget(USimpleLocalPlayer* LocalPlayer);
	void AddLayoutToViewport(USimpleLocalPlayer* LocalPlayer, USimplePrimaryLayout* Layout);
	void RemoveLayout(USimpleLocalPlayer* LocalPlayer);
protected:
	TWeakObjectPtr<ULocalPlayer> PrimaryPlayer;

	UPROPERTY(Transient)
	TArray<FRootViewportLayoutInfo> RootViewportLayouts;

	UPROPERTY(EditAnywhere, Category = "Simple | UI")
	TSoftClassPtr<USimplePrimaryLayout> PrimaryLayoutClass;
};
