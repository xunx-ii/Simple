// Fill out your copyright notice in the Description page of Project Settings.


#include "Animation/SimpleAnimInstance.h"
#include "Player/SimpleCharacterBase.h"
#include "Player/SimpleCharacterMovementComponent.h"

USimpleAnimInstance::USimpleAnimInstance()
{

}

void USimpleAnimInstance::NativeUpdateAnimation(float DeltaSeconds)
{
	Super::NativeUpdateAnimation(DeltaSeconds);

	const ASimpleCharacterBase* Character = Cast<ASimpleCharacterBase>(GetOwningActor());
	if (!Character)
	{
		return;
	}

	USimpleCharacterMovementComponent* CharMoveComp = CastChecked<USimpleCharacterMovementComponent>(Character->GetCharacterMovement());
	const FSimpleCharacterGroundInfo& GroundInfo = CharMoveComp->GetGroundInfo();
	GroundDistance = GroundInfo.GroundDistance;
}
