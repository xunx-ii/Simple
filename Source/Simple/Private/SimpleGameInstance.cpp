// Fill out your copyright notice in the Description page of Project Settings.

#include "SimpleGameInstance.h"
#include "Player/SimpleLocalPlayer.h"
#include "Engine/AssetManager.h"
#include "Blueprint/UserWidget.h"
#include "UI/SimplePrimaryLayout.h"
#include "GameFramework/HUD.h"
#include "CommonActivatableWidget.h"
#include "UI/SimpleGameWidget.h"

USimpleGameInstance::USimpleGameInstance(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	
}

void USimpleGameInstance::CreateLayoutWidget(USimpleLocalPlayer* LocalPlayer)
{
	if (APlayerController* PlayerController = LocalPlayer->GetPlayerController(GetWorld()))
	{
		TSubclassOf<USimplePrimaryLayout> LayoutWidgetClass = PrimaryLayoutClass.LoadSynchronous();
		if (ensure(LayoutWidgetClass && !LayoutWidgetClass->HasAnyClassFlags(CLASS_Abstract)))
		{
			USimplePrimaryLayout* NewLayoutObject = CreateWidget<USimplePrimaryLayout>(PlayerController, LayoutWidgetClass);
			RootViewportLayouts.Emplace(LocalPlayer, NewLayoutObject, true);
			AddLayoutToViewport(LocalPlayer, NewLayoutObject);
		}
	}
}

void USimpleGameInstance::AddLayoutToViewport(USimpleLocalPlayer* LocalPlayer, USimplePrimaryLayout* Layout)
{
	Layout->SetPlayerContext(FLocalPlayerContext(LocalPlayer));
	Layout->AddToPlayerScreen(1000);

#if WITH_EDITOR
	if (GIsEditor && LocalPlayer->IsPrimaryPlayer())
	{
		// So our controller will work in PIE without needing to click in the viewport
		FSlateApplication::Get().SetUserFocusToGameViewport(0);
	}
#endif
}

void USimpleGameInstance::NotifyPlayerAdded(USimpleLocalPlayer* LocalPlayer)
{
	LocalPlayer->OnPlayerControllerSet.AddWeakLambda(this, [this](USimpleLocalPlayer* LocalPlayer, APlayerController* PlayerController)
		{
			RemoveLayout(LocalPlayer);
			
			if (FRootViewportLayoutInfo* LayoutInfo = RootViewportLayouts.FindByKey(LocalPlayer))
			{
				AddLayoutToViewport(LocalPlayer, LayoutInfo->RootLayout);
				LayoutInfo->bAddedToViewport = true;
			}
			else
			{
				CreateLayoutWidget(LocalPlayer);
			}
		});

	if (FRootViewportLayoutInfo* LayoutInfo = RootViewportLayouts.FindByKey(LocalPlayer))
	{
		AddLayoutToViewport(LocalPlayer, LayoutInfo->RootLayout);
		LayoutInfo->bAddedToViewport = true;
	}
	else
	{
		CreateLayoutWidget(LocalPlayer);
	}
	
}

void USimpleGameInstance::RemoveLayout(USimpleLocalPlayer* LocalPlayer)
{
	if (FRootViewportLayoutInfo* LayoutInfo = RootViewportLayouts.FindByKey(LocalPlayer))
	{
		TWeakPtr<SWidget> LayoutSlateWidget = LayoutInfo->RootLayout->GetCachedWidget();
		if (LayoutSlateWidget.IsValid())
		{
			UE_LOG(LogClass, Log, TEXT("[%s] is removing player [%s]'s root layout [%s] from the viewport"), *GetName(), *GetNameSafe(LocalPlayer), *GetNameSafe(LayoutInfo->RootLayout));

			LayoutInfo->RootLayout->RemoveFromParent();
			if (LayoutSlateWidget.IsValid())
			{
				UE_LOG(LogClass, Log, TEXT("Player [%s]'s root layout [%s] has been removed from the viewport, but other references to its underlying Slate widget still exist. Noting in case we leak it."), *GetNameSafe(LocalPlayer), *GetNameSafe(LayoutInfo->RootLayout));
			}
		}
		LayoutInfo->bAddedToViewport = false;
	}
}

void USimpleGameInstance::NotifyPlayerDestroyed(USimpleLocalPlayer* LocalPlayer)
{
	RemoveLayout(LocalPlayer);
	LocalPlayer->OnPlayerControllerSet.RemoveAll(this);
	const int32 LayoutInfoIdx = RootViewportLayouts.IndexOfByKey(LocalPlayer);
	if (LayoutInfoIdx != INDEX_NONE)
	{
		USimplePrimaryLayout* Layout = RootViewportLayouts[LayoutInfoIdx].RootLayout;
		RootViewportLayouts.RemoveAt(LayoutInfoIdx);

		TWeakPtr<SWidget> LayoutSlateWidget = Layout->GetCachedWidget();
		if (LayoutSlateWidget.IsValid())
		{
			Layout->RemoveFromParent();
		}
	}
}

int32 USimpleGameInstance::AddLocalPlayer(ULocalPlayer* NewPlayer, FPlatformUserId UserId)
{
	int32 ReturnVal = Super::AddLocalPlayer(NewPlayer, UserId);
	if (ReturnVal != INDEX_NONE)
	{
		if (!PrimaryPlayer.IsValid())
		{
			UE_LOG(LogClass, Log, TEXT("AddLocalPlayer: Set %s to Primary Player"), *NewPlayer->GetName());
			PrimaryPlayer = NewPlayer;
		}

		NotifyPlayerAdded(Cast<USimpleLocalPlayer>(NewPlayer));
	}

	return ReturnVal;
}

bool USimpleGameInstance::RemoveLocalPlayer(ULocalPlayer* ExistingPlayer)
{
	if (PrimaryPlayer == ExistingPlayer)
	{
		PrimaryPlayer.Reset();
		UE_LOG(LogClass, Log, TEXT("RemoveLocalPlayer: Unsetting Primary Player from %s"), *ExistingPlayer->GetName());
	}

	NotifyPlayerDestroyed(Cast<USimpleLocalPlayer>(ExistingPlayer));

	return Super::RemoveLocalPlayer(ExistingPlayer);
}

USimplePrimaryLayout* USimpleGameInstance::GetPrimaryLayout(USimpleLocalPlayer* LocalPlayer)
{
	const FRootViewportLayoutInfo* LayoutInfo = RootViewportLayouts.FindByKey(LocalPlayer);
	return LayoutInfo ? LayoutInfo->RootLayout : nullptr;
}

bool USimpleGameInstance::PushWidgetToLayerStackOfGamePlayTag(FSimpleGameWidgetRequest SimpleGameWidgetRequest)
{
	if (!PrimaryPlayer.IsValid())
	{
		return false;
	}

	ULocalPlayer* LocalPlayer = PrimaryPlayer.Get();

	if (!LocalPlayer)
	{
		return false;
	}

	if (FRootViewportLayoutInfo* LayoutInfo = RootViewportLayouts.FindByKey(LocalPlayer))
	{
		if (TSubclassOf<UCommonActivatableWidget> ConcreteWidgetClass = SimpleGameWidgetRequest.SimpleGameWidgetClass.Get())
		{
			if (ConcreteWidgetClass == nullptr)
			{
				return false;
			}

			LayoutInfo->RootLayout->PushWidgetToLayerStack(SimpleGameWidgetRequest.LayerID, ConcreteWidgetClass);
		}
	}

	return true;
}