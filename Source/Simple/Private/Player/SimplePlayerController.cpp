// Fill out your copyright notice in the Description page of Project Settings.

#include "Player/SimplePlayerController.h"
#include "Player/SimplePlayerState.h"
#include "Abilities/SimpleAbilitySystemComponent.h"
#include "Player/SimpleLocalPlayer.h"

ASimplePlayerController::ASimplePlayerController()
{

}

void ASimplePlayerController::ReceivedPlayer()
{
	Super::ReceivedPlayer();

	if (USimpleLocalPlayer* LocalPlayer = Cast<USimpleLocalPlayer>(Player))
	{
		LocalPlayer->OnPlayerControllerSet.Broadcast(LocalPlayer, this);

		if (PlayerState)
		{
			LocalPlayer->OnPlayerStateSet.Broadcast(LocalPlayer, PlayerState);
		}
	}
}

void ASimplePlayerController::PostProcessInput(const float DeltaTime, const bool bGamePaused)
{

	ASimplePlayerState* SimplePlayerState = CastChecked<ASimplePlayerState>(PlayerState, ECastCheckedType::NullAllowed);

	if (SimplePlayerState)
	{
		USimpleAbilitySystemComponent* AbilitySystemComponent = SimplePlayerState->GetSimpleAbilitySystemComponent();
		if (AbilitySystemComponent)
		{
			AbilitySystemComponent->ProcessAbilityInput(DeltaTime, bGamePaused);
		}
	}

	Super::PostProcessInput(DeltaTime, bGamePaused);
}
