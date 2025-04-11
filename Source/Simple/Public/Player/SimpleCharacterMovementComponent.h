// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "SimpleCharacterMovementComponent.generated.h"

USTRUCT(BlueprintType)
struct FSimpleCharacterGroundInfo
{
	GENERATED_BODY()

	FSimpleCharacterGroundInfo()
		: LastUpdateFrame(0)
		, GroundDistance(0.0f)
	{}

	uint64 LastUpdateFrame;

	UPROPERTY(BlueprintReadOnly)
	FHitResult GroundHitResult;

	UPROPERTY(BlueprintReadOnly)
	float GroundDistance;
};

UCLASS()
class SIMPLE_API USimpleCharacterMovementComponent : public UCharacterMovementComponent
{
	GENERATED_BODY()
public:
	USimpleCharacterMovementComponent();

	UFUNCTION(BlueprintCallable, Category = "Simple|CharacterMovement")
	const FSimpleCharacterGroundInfo& GetGroundInfo();

	virtual void SimulateMovement(float DeltaTime) override;

protected:

	FSimpleCharacterGroundInfo CachedGroundInfo;

	UPROPERTY(Transient)
	bool bHasReplicatedAcceleration;
};
