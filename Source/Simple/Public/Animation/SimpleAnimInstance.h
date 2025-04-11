// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimInstance.h"
#include "SimpleAnimInstance.generated.h"

/**
 * 
 */
UCLASS()
class SIMPLE_API USimpleAnimInstance : public UAnimInstance
{
	GENERATED_BODY()
public:
	USimpleAnimInstance();

protected:
	virtual void NativeUpdateAnimation(float DeltaSeconds) override;

protected:
	UPROPERTY(BlueprintReadOnly, Category = "Character State Data")
	float GroundDistance = -1.0f;
};
